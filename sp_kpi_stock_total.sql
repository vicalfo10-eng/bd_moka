DELIMITER $$

DROP PROCEDURE IF EXISTS sp_kpi_stock_total$$

CREATE PROCEDURE sp_kpi_stock_total()

BEGIN

    DECLARE v_stock_total INT DEFAULT 0;

    SELECT SUM(stock) INTO v_stock_total 
    FROM productos 
    WHERE activo = 1;

    IF v_stock_total IS NOT NULL THEN
	
        SELECT 
            v_stock_total AS total,
            200 AS status,
            'Stock total calculado' AS msg,
            1 AS ok;
    ELSE
	
        SELECT 
            0 AS total,
            404 AS status,
            'No hay productos activos registrados' AS msg,
            0 AS ok;
			
    END IF;
	
END$$

DELIMITER $$