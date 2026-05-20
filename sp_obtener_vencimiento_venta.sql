DELIMITER $$

DROP PROCEDURE IF EXISTS sp_obtener_vencimiento_venta$$

CREATE PROCEDURE sp_obtener_vencimiento_venta(
    IN p_id_venta INT
)

BEGIN

    DECLARE v_fecha_final DATE DEFAULT NULL;

    SELECT MAX(pp.fecha_vencimiento) INTO v_fecha_final
    FROM cuentas_cobrar cc
    INNER JOIN plan_pagos pp
        ON cc.id_cxc = pp.id_cxc
    WHERE cc.id_venta = p_id_venta;

    IF v_fecha_final IS NOT NULL THEN

        SELECT 
            v_fecha_final AS fecha_vencimiento, 
            200 AS status, 
            'Fecha de vencimiento obtenida correctamente' AS msg, 
            1 AS ok;
    ELSE
    
        SELECT 
            NULL AS fecha_vencimiento,
            404 AS status, 
            'No se encontraron registros de pago para esta venta' AS msg, 
            0 AS ok;
    END IF;
    
END$$

DELIMITER ;