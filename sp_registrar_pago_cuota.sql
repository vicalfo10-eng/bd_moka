DELIMITER $$

DROP PROCEDURE IF EXISTS sp_registrar_pago_cuota$$

CREATE PROCEDURE sp_registrar_pago_cuota(
    IN p_id_cuota INT,
    IN p_id_cxc INT,
    IN p_id_usuario INT,
    IN p_monto_pagado DECIMAL(12,2),
    IN p_metodo_pago ENUM('EFECTIVO', 'TRANSFERENCIA', 'SINPE', 'TARJETA'),
    IN p_comprobante VARCHAR(100),
    IN p_fecha_pago DATE
)
BEGIN

    -- Variables de control
    DECLARE v_id_venta INT;
    DECLARE v_saldo_cuota_actual DECIMAL(12,2);
    DECLARE v_saldo_actual_cxc DECIMAL(12,2);
    DECLARE v_nuevo_saldo_cuota DECIMAL(12,2);
    DECLARE v_nuevo_saldo_cxc DECIMAL(12,2);
    DECLARE v_fecha_hora_pago DATETIME;

    -- Margen de tolerancia para ajuste por centavos de redondeo (Menor a 1 colón)
    DECLARE v_tolerancia_redondeo DECIMAL(5,2) DEFAULT 1.00;
    
    -- Manejo de errores
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT
            0 AS ok,
            500 AS status,
            'Error crítico: La transacción ha sido revertida' AS msg;
    END;

    -- Combinar fecha proporcionada con hora actual del servidor
    SET v_fecha_hora_pago = TIMESTAMP(p_fecha_pago, CURTIME());

    START TRANSACTION;

    -- 1. Bloqueo y obtención de saldos actuales
    SELECT id_venta, saldo_pendiente
        INTO v_id_venta, v_saldo_actual_cxc 
    FROM cuentas_cobrar
    WHERE id_cxc = p_id_cxc FOR UPDATE;

    SELECT saldo_cuota
        INTO v_saldo_cuota_actual 
    FROM plan_pagos
    WHERE id_cuota = p_id_cuota FOR UPDATE;

    -- 2. Validaciones de seguridad
    IF v_id_venta IS NULL THEN
        ROLLBACK;
        SELECT
            0 AS ok,
            404 AS status,
            'Error: Cuenta por cobrar no localizada' AS msg;
    ELSEIF v_saldo_cuota_actual <= 0 THEN
        ROLLBACK;
        SELECT
            0 AS ok,
            400 AS status,
            'Error: Esta cuota ya no tiene saldo pendiente' AS msg;
    ELSE

        -- 3. Registrar el movimiento en abonos_credito
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
            v_fecha_hora_pago
        );

        -- 4. Lógica de saldos para la Cuota
        -- Si el pago es mayor al saldo de la cuota, el nuevo saldo es 0
        SET v_nuevo_saldo_cuota = v_saldo_cuota_actual - p_monto_pagado;
        
        IF v_nuevo_saldo_cuota <= v_tolerancia_redondeo THEN
            UPDATE plan_pagos 
            SET saldo_cuota = 0,
                estado = 'PAGADA',
                fecha_pago_real = v_fecha_hora_pago
            WHERE id_cuota = p_id_cuota;
        ELSE
            UPDATE plan_pagos 
            SET saldo_cuota = v_nuevo_saldo_cuota,
                estado = 'PARCIAL',
                fecha_pago_real = v_fecha_hora_pago
            WHERE id_cuota = p_id_cuota;
        END IF;

        -- 5. Actualización del saldo global de la Cuenta por Cobrar
        SET v_nuevo_saldo_cxc = v_saldo_actual_cxc - p_monto_pagado;
        
        IF v_nuevo_saldo_cxc < v_tolerancia_redondeo THEN
            SET v_nuevo_saldo_cxc = 0;
        END IF;

        UPDATE cuentas_cobrar 
        SET saldo_pendiente = v_nuevo_saldo_cxc,
            estado = IF(v_nuevo_saldo_cxc <= 0, 'CANCELADA', 'VIGENTE')
        WHERE id_cxc = p_id_cxc;

        -- 6. Sincronización con estado de Venta
        IF v_nuevo_saldo_cxc <= 0 THEN
            UPDATE ventas
            SET estado_pago = 'PAGADA'
            WHERE id_venta = v_id_venta;
        END IF;

        COMMIT;
        
        SELECT 
            1 AS ok, 
            201 AS status, 
            'Abono procesado exitosamente' AS msg, 
            v_nuevo_saldo_cxc AS nuevo_saldo,
            -- Datos para el recibo:
            p_id_cuota AS receipt_number,
            v_fecha_hora_pago AS date,
            (SELECT nombre FROM clientes WHERE id_cliente = 
                (SELECT id_cliente FROM cuentas_cobrar WHERE id_cxc = p_id_cxc)) AS customer_name,
            v_id_venta AS invoice_ref;
    
    END IF;

END$$

DELIMITER ;