DELIMITER $$

DROP PROCEDURE IF EXISTS sp_obtener_historial_inventario$$

CREATE PROCEDURE sp_obtener_historial_inventario(
    IN p_codigo_busqueda VARCHAR(50),
    IN p_pagina INT,
    IN p_tamano_pagina INT
)
BEGIN
    DECLARE v_offset INT DEFAULT 0;
    
    -- Cálculo del offset
    SET v_offset = (p_pagina - 1) * p_tamano_pagina;

    -- Consulta con paginación
    SELECT 
        i.fecha_creacion AS fecha, 
        p.codigo AS codigo_producto, 
        p.nombre AS nombre_producto, 
        i.tipo, 
        i.cantidad,
        i.descripcion,
        u.nombre AS nombre_usuario,
        -- Subconsulta para el total de registros (útil para la paginación en el front)
        (SELECT COUNT(*) 
         FROM movimientos_inventario mi
         JOIN productos mp ON mi.id_producto = mp.id_producto
         WHERE (p_codigo_busqueda IS NULL OR p_codigo_busqueda = '' OR mp.codigo = p_codigo_busqueda)
        ) AS total_registros
    FROM movimientos_inventario i
    JOIN productos p ON i.id_producto = p.id_producto
    JOIN usuarios u ON i.id_usuario = u.id_usuario
    WHERE (p_codigo_busqueda IS NULL OR p_codigo_busqueda = '' OR p.codigo = p_codigo_busqueda)
    ORDER BY i.fecha_creacion DESC
    LIMIT v_offset, p_tamano_pagina; -- En MySQL: LIMIT offset, row_count
    
END$$

DELIMITER ;