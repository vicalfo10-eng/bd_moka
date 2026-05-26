DELIMITER $$

DROP PROCEDURE IF EXISTS sp_obtener_plan_pagos$$

CREATE PROCEDURE sp_obtener_plan_pagos(
    IN p_id_cxc INT
)
BEGIN

    DECLARE v_existe INT DEFAULT 0;

    -- Validar si existen cuotas para esa cuenta por cobrar
    SELECT COUNT(*) INTO v_existe 
    FROM plan_pagos 
    WHERE id_cxc = p_id_cxc;

    IF v_existe > 0 THEN
        -- Si existen, devolvemos el listado con los flags de éxito
        SELECT 
            pp.id_cuota,
            pp.id_cxc,
            pp.numero_cuota,
            pp.monto_cuota AS amount,
            pp.saldo_cuota AS balance,
            pp.fecha_vencimiento AS due_date,
            pp.estado AS status_text,
            200 AS status,
            'Plan de pagos recuperado' AS msg,
            1 AS ok
        FROM plan_pagos pp
        WHERE pp.id_cxc = p_id_cxc
        ORDER BY pp.numero_cuota ASC;
    ELSE
        -- Si no hay cuotas (por ejemplo, una cuenta anulada o mal generada)
        SELECT 
            404 AS status, 
            'No se encontró un plan de pagos para esta cuenta' AS msg,
            0 AS ok;
    END IF;

END$$

DELIMITER ;