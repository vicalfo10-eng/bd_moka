DELIMITER $$

DROP PROCEDURE IF EXISTS sp_rpt_top_vendidos$$

CREATE PROCEDURE sp_rpt_top_vendidos()

BEGIN

    DECLARE v_conteo INT DEFAULT 0;

    SELECT COUNT(*) INTO v_conteo FROM detalle_ventas;

    IF v_conteo > 0 THEN
	
        SELECT 
            p.codigo,
            p.nombre,
            SUM(dv.cantidad) AS total_unidades,
            SUM(dv.subtotal) AS total_ingresos,
            200 AS status,
            'Top 10 generado exitosamente' AS msg,
            1 AS ok
        FROM detalle_ventas dv
        JOIN productos p ON dv.id_producto = p.id_producto
        GROUP BY p.id_producto, p.codigo, p.nombre
        ORDER BY total_unidades DESC
        LIMIT 10;
		
    ELSE

        SELECT 
            NULL AS codigo,
            NULL AS nombre,
            0 AS total_unidades,
            0 AS total_ingresos,
            404 AS status,
            'No se encontraron ventas registradas para generar el ranking' AS msg,
            0 AS ok;
    END IF;
	
END$$

DELIMITER $$