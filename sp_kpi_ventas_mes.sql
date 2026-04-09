DELIMITER $$

DROP PROCEDURE IF EXISTS sp_kpi_ventas_mes$$

CREATE PROCEDURE sp_kpi_ventas_mes()

BEGIN

    DECLARE v_total DECIMAL(18,2) DEFAULT 0;

    SELECT SUM(total)INTO v_total 
    FROM ventas 
    WHERE MONTH(fecha_creacion) = MONTH(CURRENT_DATE()) 
      AND YEAR(fecha_creacion) = YEAR(CURRENT_DATE());

    IF v_total IS NOT NULL THEN
	
        SELECT 
            v_total AS total,
            200 AS status,
            'Ventas del mes obtenidas correctamente' AS msg,
            1 AS ok;
    ELSE
	
        SELECT 
            0 AS total,
            200 AS status,
            'No se registran ventas en el mes actual' AS msg,
            1 AS ok;
			
    END IF;
	
END$$

DELIMITER $$