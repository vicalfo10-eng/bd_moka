DELIMITER $$

DROP PROCEDURE IF EXISTS sp_registrar_venta$$

CREATE PROCEDURE sp_registrar_venta(
    IN p_id_usuario INT,
    IN p_id_cliente INT,
    IN p_detalles_json JSON
)

BEGIN

    DECLARE v_id_venta INT;
    DECLARE v_total_venta DECIMAL(12,2) DEFAULT 0;
    DECLARE v_productos_sin_stock TEXT;

    -- 1. Manejo de errores global
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 @p2 = MESSAGE_TEXT;
        ROLLBACK;
        SELECT 500 AS status, CONCAT('Error crítico en BD: ', @p2) AS msg, 0 AS ok;
    END;

    -- 2. CALCULAR EL TOTAL DESDE EL JSON (Antes de insertar nada)
    SELECT SUM(jt.total_linea) INTO v_total_venta
    FROM JSON_TABLE(p_detalles_json, '$[*]' COLUMNS (
        total_linea DECIMAL(12,2) PATH '$.total_linea'
    )) AS jt;

    START TRANSACTION;

    -- 3. Crear Cabecera de Venta (Ya con el total final)
    INSERT INTO ventas (id_cliente, id_usuario, total, fecha_creacion)
    VALUES (p_id_cliente, p_id_usuario, v_total_venta, NOW());
    
    SET v_id_venta = LAST_INSERT_ID();

    -- 4. Insertar Detalle de Ventas
    INSERT INTO detalle_ventas (
        id_venta, id_producto, cantidad, precio, 
        subtotal, impuesto, total_impuesto, descuento, total_linea
    )
    SELECT v_id_venta, jt.id_producto, jt.cantidad, jt.precio, jt.subtotal, 
           jt.impuesto, jt.total_impuesto, jt.descuento, jt.total_linea
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

    -- 5. Rebajar el Stock
    UPDATE productos p
    JOIN JSON_TABLE(p_detalles_json, '$[*]' COLUMNS (
        id INT PATH '$.id_producto', 
        cant INT PATH '$.cantidad'
    )) AS jt ON p.id_producto = jt.id
    SET p.stock = p.stock - jt.cant;

    -- 6. VERIFICACIÓN DE STOCK ESPECÍFICA Y DETALLADA
    -- Buscamos los nombres de los productos que quedaron en negativo tras el UPDATE
    SELECT GROUP_CONCAT(p.nombre SEPARATOR ', ') INTO v_productos_sin_stock
    FROM productos p
    JOIN JSON_TABLE(p_detalles_json, '$[*]' COLUMNS (id INT PATH '$.id_producto')) AS jt 
      ON p.id_producto = jt.id
    WHERE p.stock < 0;

    -- 7. Evaluación final
    IF v_productos_sin_stock IS NOT NULL THEN
        ROLLBACK;
        SELECT 400 AS status, 
               CONCAT('Stock insuficiente para: ', v_productos_sin_stock) AS msg, 
               0 AS ok;
    ELSE
        -- Paso extra: Registrar movimientos solo si el stock fue exitoso
        INSERT INTO movimientos_inventario (id_producto, id_usuario, tipo, cantidad, descripcion, fecha_creacion)
        SELECT jt.id_producto, p_id_usuario, 'SALIDA', jt.cantidad, 
               CONCAT('Venta Factura #', v_id_venta), NOW()
        FROM JSON_TABLE(p_detalles_json, '$[*]' COLUMNS (
            id_producto INT PATH '$.id_producto',
            cantidad INT PATH '$.cantidad'
        )) AS jt;

        COMMIT;
        SELECT 201 AS status, 'Venta registrada correctamente' AS msg, 1 AS ok, v_id_venta AS factura;
    END IF;

END$$

DELIMITER ;