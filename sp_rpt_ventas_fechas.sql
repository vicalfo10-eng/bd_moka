DELIMITER $$

DROP PROCEDURE IF EXISTS sp_rpt_ventas_fechas$$

CREATE PROCEDURE sp_rpt_ventas_fechas(
    IN p_fecha_inicio DATE,
    IN p_fecha_fin DATE,
	IN p_pagina INT,
    IN p_tamano_pagina INT
)

BEGIN

    DECLARE v_conteo, v_offset INT DEFAULT 0;
	
	-- Cálculo del offset
    SET v_offset = (p_pagina - 1) * p_tamano_pagina;

    -- Contar si hay registros en ese rango
    SELECT COUNT(*) INTO v_conteo 
    FROM ventas 
    WHERE DATE(fecha_creacion) BETWEEN p_fecha_inicio AND p_fecha_fin;

    IF v_conteo > 0 THEN
	
        SELECT 
            v.id_venta,
            DATE_FORMAT(v.fecha_creacion, '%d/%m/%Y %H:%i') AS fecha,
            COALESCE(c.nombre, 'Consumidor Final') AS cliente,
            u.nombre AS vendedor,
            v.total,
			v_conteo AS total_registros,
            200 AS status,
            'Reporte generado exitosamente' AS msg,
            1 AS ok
        FROM ventas v
        LEFT JOIN clientes c ON v.id_cliente = c.id_cliente
        JOIN usuarios u ON v.id_usuario = u.id_usuario
        WHERE DATE(v.fecha_creacion) BETWEEN p_fecha_inicio AND p_fecha_fin
        ORDER BY v.fecha_creacion DESC
		LIMIT v_offset, p_tamano_pagina;
		
    ELSE
	
        SELECT 
            404 AS status,
            'No se encontraron ventas en el rango seleccionado' AS msg,
            0 AS ok;
			
    END IF;
	
END$$

DELIMITER ;