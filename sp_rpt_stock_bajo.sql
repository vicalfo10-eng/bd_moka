DELIMITER $$

DROP PROCEDURE IF EXISTS sp_rpt_stock_bajo$$

CREATE PROCEDURE sp_rpt_stock_bajo(
    IN p_pagina INT,
    IN p_tamano_pagina INT
)
BEGIN
    DECLARE v_conteo, v_offset INT DEFAULT 0;
    
    -- Cálculo del offset para la paginación
    SET v_offset = (p_pagina - 1) * p_tamano_pagina;
    
    -- Contamos productos donde el stock actual sea menor o igual a su propio mínimo configurado
    SELECT COUNT(*) INTO v_conteo 
    FROM productos 
    WHERE stock <= stock_minimo AND activo = 1;

    IF v_conteo > 0 THEN
	
        SELECT 
            codigo,
            nombre,
            stock,
            stock_minimo,
			v_conteo AS total_registros,
            200 AS status,
            'Reporte de stock bajo generado' AS msg,
            1 AS ok 
        FROM productos
        WHERE stock <= stock_minimo -- Validación contra columna de la tabla
            AND activo = 1 
        ORDER BY stock ASC
        LIMIT v_offset, p_tamano_pagina;
        
    ELSE
        SELECT
            404 AS status, 
            'No hay productos por debajo de su stock mínimo configurado' AS msg,
            0 AS ok;
    END IF;
    
END$$

DELIMITER ;