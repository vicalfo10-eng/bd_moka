DELIMITER $$

DROP PROCEDURE IF EXISTS sp_obtener_usuario$$

CREATE PROCEDURE sp_obtener_usuario(
    IN p_identificacion VARCHAR(50)
)
BEGIN

    DECLARE v_existe INT DEFAULT 0;

    -- Validar si el usuario existe
    SELECT COUNT(*) INTO v_existe 
    FROM usuarios 
    WHERE identificacion = p_identificacion;

    IF v_existe > 0 THEN
	
        -- Si existe, devolvemos los datos y un flag de éxito
        SELECT
			id_rol,
			identificacion,
            nombre, 
            correo,
			contrasena,
            activo,
            200 AS status,
            'Usuario encontrado' AS msg,
            1 AS ok
        FROM usuarios
        WHERE identificacion = p_identificacion;
		
    ELSE
	
        -- Si no existe, devolvemos un status 404 o informativo
        SELECT
		
            404 AS status, 
            'No se encontró ningún usuario con está identificación' AS msg,
            0 AS ok;
    END IF;

END$$

DELIMITER ;