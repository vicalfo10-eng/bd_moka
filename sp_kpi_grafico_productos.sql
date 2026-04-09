DELIMITER $$

DROP PROCEDURE IF EXISTS sp_kpi_grafico_productos$$

CREATE PROCEDURE sp_kpi_grafico_productos()

BEGIN

    DECLARE v_existen_ventas INT;

    -- Verificamos si hay detalles de ventas registrados
    SELECT COUNT(*) INTO v_existen_ventas FROM detalle_ventas;

    IF v_existen_ventas > 0 THEN
	
        SELECT 
            p.nombre,
            SUM(dv.cantidad) AS cantidad,
            200 AS status,
            'Top 5 productos más vendidos obtenido' AS msg,
            1 AS ok
        FROM detalle_ventas dv
        JOIN productos p ON dv.id_producto = p.id_producto
        GROUP BY p.id_producto, p.nombre
        ORDER BY cantidad DESC
        LIMIT 5;
		
    ELSE
	
        SELECT 
            'Sin datos' AS nombre, 
            0 AS cantidad, 
            200 AS status, 
            'Aún no hay ventas registradas para generar el top' AS msg, 
            1 AS ok;
			
    END IF;
	
END$$

DELIMITER ;