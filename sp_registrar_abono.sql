DELIMITER $$

DROP PROCEDURE IF EXISTS sp_registrar_abono$$

CREATE PROCEDURE sp_registrar_abono(
    IN p_id_cxc INT,
    IN p_id_usuario INT,
    IN p_monto_abono DECIMAL(12,2),
    IN p_metodo_pago VARCHAR(50),
    IN p_comprobante VARCHAR(100)
)

BEGIN

    DECLARE v_monto_restante DECIMAL(12,2);
    DECLARE v_cuota_id INT;
    DECLARE v_cuota_monto_pendiente DECIMAL(12,2);
    DECLARE v_saldo_cxc_actual DECIMAL(12,2);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT
            500 AS status,
            'Error al procesar el abono' AS msg,
            0 AS ok;
    END;

    START TRANSACTION;

    -- 1. Registrar el Abono en el historial
    INSERT INTO abonos_credito (
        id_cxc,
        id_usuario,
        monto,
        metodo_pago,
        comprobante
    )
    VALUES (
        p_id_cxc,
        p_id_usuario,
        p_monto_abono,
        p_metodo_pago,
        p_comprobante
    );

    -- 2. Lógica de cascada para aplicar el abono a las cuotas
    SET v_monto_restante = p_monto_abono;

    -- Buscamos cuotas pendientes o parciales en orden correlativo
    WHILE v_monto_restante > 0 DO
        SET v_cuota_id = NULL;

        -- Seleccionar la cuota más antigua que no esté pagada
        SELECT
            id_cuota,
            monto_cuota INTO v_cuota_id,
            v_cuota_monto_pendiente
        FROM plan_pagos
        WHERE id_cxc = p_id_cxc
            AND estado IN ('PENDIENTE', 'PARCIAL', 'MORA')
        ORDER BY numero_cuota ASC LIMIT 1;

        IF v_cuota_id IS NULL THEN
            -- Si ya no hay más cuotas pendientes pero sobra dinero (pago en exceso)
            SET v_monto_restante = 0;
        ELSE
            IF v_monto_restante >= v_cuota_monto_pendiente THEN
                -- El abono cubre toda la cuota
                UPDATE plan_pagos
                SET 
                    estado = 'PAGADA', 
                    monto_cuota = 0, 
                    fecha_pago_real = NOW() 
                WHERE id_cuota = v_cuota_id;
                
                SET v_monto_restante = v_monto_restante - v_cuota_monto_pendiente;

            ELSE
                -- El abono es parcial para esta cuota
                UPDATE plan_pagos
                SET 
                    estado = 'PARCIAL', 
                    monto_cuota = monto_cuota - v_monto_restante 
                WHERE id_cuota = v_cuota_id;
                
                SET v_monto_restante = 0;

            END IF;

        END IF;
    END WHILE;

    -- 3. Actualizar el saldo general de la Cuenta por Cobrar
    UPDATE cuentas_cobrar 
    SET saldo_pendiente = saldo_pendiente - p_monto_abono 
    WHERE id_cxc = p_id_cxc;

    -- 4. Si el saldo llega a 0, cerrar la cuenta y la venta
    SELECT
        saldo_pendiente INTO v_saldo_cxc_actual
    FROM cuentas_cobrar
    WHERE id_cxc = p_id_cxc;

    IF v_saldo_cxc_actual <= 0 THEN

        UPDATE cuentas_cobrar
        SET estado = 'CANCELADA'
        WHERE id_cxc = p_id_cxc;

        UPDATE ventas
        SET estado_pago = 'PAGADA' 
        WHERE id_venta = (
            SELECT id_venta
            FROM cuentas_cobrar
            WHERE id_cxc = p_id_cxc
        );

    END IF;

    COMMIT;
    SELECT
        200 AS status,
        'Abono procesado exitosamente' AS msg,
        1 AS ok;
        
END$$

DELIMITER ;