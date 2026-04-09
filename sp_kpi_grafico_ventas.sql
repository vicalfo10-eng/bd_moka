DELIMITER $$

DROP PROCEDURE IF EXISTS sp_kpi_grafico_ventas$$

CREATE PROCEDURE sp_kpi_grafico_ventas()

BEGIN
    -- Validamos si hay datos en el rango para personalizar el mensaje
    DECLARE v_conteo INT;
    
    SELECT COUNT(*) INTO v_conteo 
    FROM ventas 
    WHERE fecha_creacion >= DATE_SUB(CURDATE(), INTERVAL 7 DAY);

    IF v_conteo > 0 THEN
	
        SELECT 
            DATE_FORMAT(fecha_creacion, '%d/%m') AS dia,
            SUM(total) AS total,
            200 AS status,
            'Datos de ventas semanales obtenidos' AS msg,
            1 AS ok
        FROM ventas
        WHERE fecha_creacion >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
        GROUP BY dia 
        ORDER BY MIN(fecha_creacion) ASC;
		
    ELSE
	
        -- Respuesta estandarizada para cuando no hay ventas aún
        SELECT 
            NULL AS dia, 
            0 AS total, 
            200 AS status, 
            'Sin movimientos de ventas en los últimos 7 días' AS msg, 
            1 AS ok;
    END IF;
	
END$$

DELIMITER ;