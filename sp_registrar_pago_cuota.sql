DELIMITER $$

DROP PROCEDURE IF EXISTS sp_registrar_pago_cuota$$

CREATE PROCEDURE sp_registrar_pago_cuota(
    IN p_id_cuota INT,
    IN p_id_cxc INT,
    IN p_id_usuario INT,
    IN p_monto_pagado DECIMAL(18,2),
    IN p_metodo_pago VARCHAR(50),
    IN p_comprobante VARCHAR(100),
    IN p_fecha_pago DATE
)
BEGIN
    -- Variables de control interno
    DECLARE v_id_venta INT
    DECLARE v_monto_cuota_esperado DECIMAL(18,2)
    DECLARE v_saldo_actual_cxc DECIMAL(18,2)
    DECLARE v_estado_cuota_actual VARCHAR(20)
    DECLARE v_nuevo_saldo_cxc DECIMAL(18,2)
    
    -- Manejo de errores catastróficos
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK
        SELECT 0 AS ok, 500 AS status, 'Error crítico: La transacción ha sido revertida' AS msg
    END

    START TRANSACTION

    -- 1. Bloqueo de registros y lectura de datos actuales (Seguridad ante concurrencia)
    SELECT id_venta, saldo_pendiente INTO v_id_venta, v_saldo_actual_cxc 
    FROM cuentas_cobrar WHERE id_cxc = p_id_cxc FOR UPDATE

    SELECT monto_cuota, estado INTO v_monto_cuota_esperado, v_estado_cuota_actual 
    FROM plan_pagos WHERE id_cuota = p_id_cuota FOR UPDATE

    -- 2. Validaciones de integridad de negocio
    IF v_id_venta IS NULL THEN
        ROLLBACK
        SELECT 0 AS ok, 404 AS status, 'Error: Cuenta por cobrar no localizada' AS msg
    ELSEIF v_estado_cuota_actual = 'PAGADA' THEN
        ROLLBACK
        SELECT 0 AS ok, 400 AS status, 'Error: Esta cuota ya se encuentra cancelada' AS msg
    ELSE

        -- 3. Registrar el movimiento en abonos_credito (Con los nuevos campos)
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
            p_fecha_pago
        )

        -- 4. Actualización del Plan de Pagos
        -- Lógica: Si el monto es igual o mayor al esperado, es PAGADA. Si no, PARCIAL.
        UPDATE plan_pagos 
        SET estado = IF(p_monto_pagado >= v_monto_cuota_esperado, 'PAGADA', 'PARCIAL'),
            fecha_pago_real = p_fecha_pago
        WHERE id_cuota = p_id_cuota

        -- 5. Actualización de la Cuenta por Cobrar
        SET v_nuevo_saldo_cxc = v_saldo_actual_cxc - p_monto_pagado
        
        -- Seguridad: No permitir saldos negativos por errores de redondeo
        IF v_nuevo_saldo_cxc < 0 THEN SET v_nuevo_saldo_cxc = 0 END IF

        UPDATE cuentas_cobrar 
        SET saldo_pendiente = v_nuevo_saldo_cxc,
            estado = IF(v_nuevo_saldo_cxc <= 0, 'CANCELADO', 'ACTIVO'),
            ultima_actualizacion = NOW()
        WHERE id_cxc = p_id_cxc

        -- 6. Sincronización con el estado de la Venta
        -- Solo si el crédito se salda por completo (saldo = 0)
        IF v_nuevo_saldo_cxc <= 0 THEN
            UPDATE ventas 
            SET estado_pago = 'Pagado' 
            WHERE id_venta = v_id_venta
        END IF

        COMMIT
        
        -- Retorno de éxito con el nuevo saldo para actualizar el Front-end
        SELECT 
            1 AS ok, 
            200 AS status, 
            'Pago registrado exitosamente' AS msg, 
            v_nuevo_saldo_cxc AS nuevo_saldo
    END IF

END$$

DELIMITER ;