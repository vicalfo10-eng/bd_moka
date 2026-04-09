DELIMITER $$

DROP PROCEDURE IF EXISTS sp_obtener_proveedor$$

CREATE PROCEDURE sp_obtener_proveedor(
    IN p_identificacion VARCHAR(50)
)
BEGIN
    DECLARE v_existe INT DEFAULT 0;

    -- Validar si el cliente existe
    SELECT COUNT(*) INTO v_existe 
    FROM proveedores 
    WHERE identificacion = p_identificacion;

    IF v_existe > 0 THEN
        -- Si existe, devolvemos los datos y un flag de éxito
        SELECT 
            identificacion, 
            nombre, 
            telefono, 
            correo,
			direccion,
            activo,
            200 AS status,
            'Proveedor encontrado' AS msg,
            1 AS ok
        FROM proveedores
        WHERE identificacion = p_identificacion;
    ELSE
        -- Si no existe, devolvemos un status 404 o informativo
        SELECT 
            404 AS status, 
            'No se encontró ningún proveedor con esa identificación' AS msg,
            0 AS ok;
    END IF;

END$$

DELIMITER ;