DELIMITER $$

DROP PROCEDURE IF EXISTS sp_actualizar_usuario$$

CREATE PROCEDURE sp_actualizar_usuario(
	IN p_identificacion VARCHAR(50),
	IN p_rol INTEGER,
    IN p_nombre VARCHAR(100),
	IN p_correo VARCHAR(150),
	IN p_activo TINYINT
)

BEGIN

	DECLARE v_existe INT DEFAULT 0;

    -- Manejo de errores
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
	
        ROLLBACK;
        SELECT 500 AS status, 'Error interno al actualizar el usuario' AS msg, 0 AS ok;
    END;

    START TRANSACTION;
	
	SELECT COUNT(*) INTO v_existe
    FROM usuarios
    WHERE correo = p_correo
		AND identificacion <> p_identificacion;

    IF v_existe > 0 THEN
	
		ROLLBACK;
        SELECT 400 AS status, 'El correo ya está registrado' AS msg;

    ELSE

		-- Realizar la actualización
		UPDATE usuarios 
		SET id_rol = p_rol,
			nombre = p_nombre,
			correo = p_correo,
			activo = p_activo
		WHERE identificacion = p_identificacion;

		COMMIT;
		
		SELECT 200 AS status, 'Usuario actualizado correctamente' AS msg, 1 AS ok;

    END IF;

END$$

DELIMITER ;