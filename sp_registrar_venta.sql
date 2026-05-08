DELIMITER $$

DROP PROCEDURE IF EXISTS sp_registrar_venta$$

CREATE PROCEDURE sp_registrar_venta(
    IN p_id_usuario INT,
    IN p_id_cliente INT,
    IN p_tipo_pago ENUM('CONTADO', 'CREDITO'),
    IN p_id_config INT, -- ID del plan elegido (solo si es crédito)
    IN p_fecha_primer_pago DATE, -- Para saber cuándo inicia el cobro
    IN p_detalles_json JSON
)

BEGIN

    DECLARE v_id_venta INT;
    DECLARE v_id_cxc INT;
    DECLARE v_total_venta DECIMAL(12,2) DEFAULT 0;
    DECLARE v_productos_sin_stock TEXT;
    
    -- Variables para el cálculo de cuotas
    DECLARE v_cuotas_total INT;
    DECLARE v_frecuencia INT;
    DECLARE v_monto_cuota DECIMAL(12,2);
    DECLARE v_i INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 @p2 = MESSAGE_TEXT;
        ROLLBACK;
        SELECT
            500 AS status,
            CONCAT('Error crítico en BD: ', @p2) AS msg,
            0 AS ok;
    END;

    -- Calcular total
    SELECT
        SUM(jt.total_linea)
        INTO v_total_venta
    FROM JSON_TABLE(p_detalles_json, '$[*]' COLUMNS (total_linea DECIMAL(12,2) PATH '$.total_linea'))
    AS jt;

    START TRANSACTION;

    -- 1. Insertar Cabecera
    INSERT INTO ventas (
        id_cliente,
        id_usuario,
        total,
        tipo_pago,
        estado_pago,
        fecha_creacion)
    VALUES (
        p_id_cliente,
        p_id_usuario,
        v_total_venta,
        p_tipo_pago, 
        IF(p_tipo_pago = 'CONTADO', 'PAGADA', 'PENDIENTE'),
        NOW()
    );
    
    SET v_id_venta = LAST_INSERT_ID();

    -- 2. Detalle de Ventas
    INSERT INTO detalle_ventas (
        id_venta,
        id_producto,
        cantidad,
        precio,
        subtotal,
        impuesto,
        total_impuesto,
        descuento,
        total_linea
    )
    SELECT
        v_id_venta,
        jt.id_producto,
        jt.cantidad,
        jt.precio,
        jt.subtotal,
        jt.impuesto,
        jt.total_impuesto,
        jt.descuento,
        jt.total_linea
    FROM JSON_TABLE(p_detalles_json, '$[*]' COLUMNS (
        id_producto INT PATH '$.id_producto',
        cantidad INT PATH '$.cantidad',
        precio DECIMAL(12,2) PATH '$.precio',
        subtotal DECIMAL(12,2) PATH '$.subtotal',
        impuesto DECIMAL(5,2) PATH '$.impuesto',
        total_impuesto DECIMAL(12,2) PATH '$.total_impuesto',
        descuento DECIMAL(12,2) PATH '$.descuento',
        total_linea DECIMAL(12,2) PATH '$.total_linea'
    )) AS jt;

    -- 3. Rebajar Stock y Movimientos
    UPDATE productos p 
    JOIN JSON_TABLE(p_detalles_json, '$[*]' COLUMNS (id INT PATH '$.id_producto', cant INT PATH '$.cantidad')) AS jt
        ON p.id_producto = jt.id
    SET p.stock = p.stock - jt.cant;

    SELECT GROUP_CONCAT(p.nombre SEPARATOR ', ')
        INTO v_productos_sin_stock
    FROM productos p
    JOIN JSON_TABLE(p_detalles_json, '$[*]' COLUMNS (id INT PATH '$.id_producto')) AS jt
        ON p.id_producto = jt.id
    WHERE p.stock < 0;

    IF v_productos_sin_stock IS NOT NULL THEN

        ROLLBACK;
        SELECT
            400 AS status,
            CONCAT('Stock insuficiente para: ', v_productos_sin_stock) AS msg,
            0 AS ok;
    ELSE
        -- Registrar Inventario
        INSERT INTO movimientos_inventario (
            id_producto,
            id_usuario,
            tipo,
            cantidad,
            descripcion,
            fecha_creacion
        )
        SELECT
            jt.id_producto,
            p_id_usuario,
            'SALIDA',
            jt.cantidad,
            CONCAT('Venta Factura #', v_id_venta),
            NOW()
        FROM JSON_TABLE(p_detalles_json, '$[*]' COLUMNS (id_producto INT PATH '$.id_producto', cantidad INT PATH '$.cantidad')) AS jt;

        -- 4. LÓGICA DE CRÉDITO
        IF p_tipo_pago = 'CREDITO' THEN
            -- Obtener reglas del plan
            SELECT
                cantidad_cuotas,
                frecuencia_dias
                INTO v_cuotas_total, v_frecuencia 
            FROM configuracion_creditos
            WHERE id_config = p_id_config;

            SET v_monto_cuota = v_total_venta / v_cuotas_total;

            -- Crear Cuenta por Cobrar
            INSERT INTO cuentas_cobrar (
                id_venta,
                id_cliente,
                id_config,
                monto_total,
                saldo_pendiente,
                fecha_vencimiento_total
            )
            VALUES (
                v_id_venta,
                p_id_cliente,
                p_id_config,
                v_total_venta,
                v_total_venta, 
                DATE_ADD(p_fecha_primer_pago, INTERVAL (v_frecuencia * (v_cuotas_total - 1)) DAY)
            );
            
            SET v_id_cxc = LAST_INSERT_ID();

            -- Generar Plan de Pagos (Bucle)
            WHILE v_i < v_cuotas_total DO

                INSERT INTO plan_pagos (
                    id_cxc,
                    numero_cuota,
                    monto_cuota,
                    fecha_vencimiento,
                    estado
                )
                VALUES (
                    v_id_cxc,
                    v_i + 1,
                    v_monto_cuota,
                    DATE_ADD(p_fecha_primer_pago, INTERVAL (v_frecuencia * v_i) DAY), 'PENDIENTE');
                SET v_i = v_i + 1;

            END WHILE;
        END IF;

        COMMIT;
        SELECT
            201 AS status,
            'Venta y crédito registrados correctamente' AS msg,
            1 AS ok,
            v_id_venta AS factura;
    END IF;
    
END$$

DELIMITER ;