DELIMITER $$

DROP PROCEDURE IF EXISTS sp_registrar_pago_cuota$$

CREATE PROCEDURE sp_registrar_pago_cuota(
    IN p_id_cuota INT,
    IN p_id_cxc INT,
    IN p_id_usuario INT,
    IN p_monto_pagado DECIMAL(12,2),
    IN p_metodo_pago ENUM('EFECTIVO','TRANSFERENCIA','SINPE','TARJETA'), -- Ajustado a ENUM
    IN p_comprobante VARCHAR(100),
    IN p_fecha_pago DATETIME -- Ajustado a DATETIME según tu tabla
)
BEGIN
    -- Variables de control interno
    DECLARE v_id_venta INT;
    DECLARE v_monto_cuota_esperado DECIMAL(12,2);
    DECLARE v_saldo_actual_cxc DECIMAL(12,2);
    DECLARE v_estado_cuota_actual VARCHAR(20);
    DECLARE v_nuevo_saldo_cxc DECIMAL(12,2);
    
    -- Manejo de errores para identificar qué falló
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        -- Retornamos el error para debug
        SELECT 0 AS ok, 500 AS status, 'Error crítico: Verifique integridad de datos o llaves foráneas' AS msg;
    END;

    START TRANSACTION;

    -- 1. Lectura y Bloqueo
    SELECT id_venta, saldo_pendiente INTO v_id_venta, v_saldo_actual_cxc 
    FROM cuentas_cobrar WHERE id_cxc = p_id_cxc FOR UPDATE;

    SELECT monto_cuota, estado INTO v_monto_cuota_esperado, v_estado_cuota_actual 
    FROM plan_pagos WHERE id_cuota = p_id_cuota FOR UPDATE;

    -- 2. Validaciones
    IF v_id_venta IS NULL THEN
        ROLLBACK;
        SELECT 0 AS ok, 404 AS status, 'Error: Cuenta por cobrar no localizada' AS msg;
    ELSEIF v_estado_cuota_actual = 'PAGADA' THEN
        ROLLBACK;
        SELECT 0 AS ok, 400 AS status, 'Error: Esta cuota ya se encuentra cancelada' AS msg;
    ELSE

        -- 3. Insertar abono (Ajustado a tu estructura real)
        INSERT INTO abonos_credito (
            id_cxc,
            id_usuario,
            monto,
            metodo_pago,
            comprobante,
            fecha_abono
        ) VALUES (
            p_id_cxc,
            p_id_usuario,
            p_monto_pagado,
            p_metodo_pago,
            p_comprobante,
            IFNULL(p_fecha_pago, NOW()) -- Si la fecha viene nula usamos el timestamp
        );

        -- 4. Actualización del Plan de Pagos
        UPDATE plan_pagos 
        SET estado = IF(p_monto_pagado >= v_monto_cuota_esperado, 'PAGADA', 'PARCIAL'),
            fecha_pago_real = IFNULL(p_fecha_pago, NOW())
        WHERE id_cuota = p_id_cuota;

        -- 5. Actualización de la Cuenta por Cobrar
        SET v_nuevo_saldo_cxc = v_saldo_actual_cxc - p_monto_pagado;
        
        IF v_nuevo_saldo_cxc < 0 THEN 
            SET v_nuevo_saldo_cxc = 0; 
        END IF;

        UPDATE cuentas_cobrar 
        SET saldo_pendiente = v_nuevo_saldo_cxc,
            estado = IF(v_nuevo_saldo_cxc <= 0, 'CANCELADO', 'ACTIVO'),
            ultima_actualizacion = NOW()
        WHERE id_cxc = p_id_cxc;

        -- 6. Sincronización con Venta
        IF v_nuevo_saldo_cxc <= 0 THEN
            UPDATE ventas 
            SET estado_pago = 'Pagado' 
            WHERE id_venta = v_id_venta;
        END IF;

        COMMIT;
        
        SELECT 1 AS ok, 200 AS status, 'Pago registrado correctamente' AS msg, v_nuevo_saldo_cxc AS nuevo_saldo;
    END IF;

END$$

DELIMITER ;