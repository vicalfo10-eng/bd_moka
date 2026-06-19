DELIMITER $$

DROP PROCEDURE IF EXISTS sp_obtener_producto$$

CREATE PROCEDURE sp_obtener_producto(
    IN p_filtro VARCHAR(150)
)
BEGIN
    
    IF p_filtro IS NULL OR TRIM(p_filtro) = '' THEN

        SELECT
            id_producto,
            id_categoria,
            id_proveedor,
            codigo,
            nombre,
            precio,
            impuesto,
            stock,
            stock_minimo,
            activo,
            200 AS status,
            'Productos obtenidos' AS msg,
            1 AS ok
        FROM productos;

    ELSE

        SELECT
            id_producto,
            id_categoria,
            id_proveedor,
            codigo,
            nombre,
            precio,
            impuesto,
            stock,
            stock_minimo,
            activo,
            200 AS status,
            'Resultados obtenidos' AS msg,
            1 AS ok
        FROM productos
        WHERE ( p_filtro REGEXP '^[0-9]+$' AND codigo = p_filtro )
           OR nombre LIKE CONCAT('%', p_filtro, '%');

    END IF;

END$$

DELIMITER ;