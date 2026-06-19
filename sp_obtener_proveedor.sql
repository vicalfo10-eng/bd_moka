DELIMITER $$

DROP PROCEDURE IF EXISTS sp_obtener_proveedor$$

CREATE PROCEDURE sp_obtener_proveedor(
    IN p_filtro VARCHAR(150)
)
BEGIN
    
    IF p_filtro IS NULL OR TRIM(p_filtro) = '' THEN

        SELECT
            identificacion,
            nombre,
            telefono,
            correo,
            direccion,
            activo,
            200 AS status,
            'Proveedores obtenidos' AS msg,
            1 AS ok 
        FROM proveedores;

    ELSE
        
        SELECT
            identificacion,
            nombre,
            telefono,
            correo,
            direccion,
            activo,
            200 AS status,
            'Resultados obtenidos' AS msg,
            1 AS ok 
        FROM proveedores 
        WHERE ( p_filtro REGEXP '^[0-9]+$' AND identificacion = p_filtro )
           OR nombre LIKE CONCAT('%', p_filtro, '%');

    END IF;

END$$

DELIMITER ;