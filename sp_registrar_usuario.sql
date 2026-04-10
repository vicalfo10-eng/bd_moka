DELIMITER $$

DROP PROCEDURE IF EXISTS sp_registrar_usuario$$

CREATE PROCEDURE sp_registrar_usuario(
    IN p_identificacion VARCHAR(50),
	IN p_id_rol INT,
    IN p_nombre VARCHAR(100),
    IN p_correo VARCHAR(150),
    IN p_contrasena VARCHAR(255)
)
BEGIN

    DECLARE v_existe INT DEFAULT 0;

    -- Manejo de error SQL
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 500 AS status, 'Error interno al registrar usuario' AS msg;
    END;

    START TRANSACTION;

    -- Validar que el rol exista
    SELECT COUNT(*) INTO v_existe
    FROM roles
    WHERE id_rol = p_id_rol AND activo = 1;

    IF v_existe = 0 THEN
        ROLLBACK;
        SELECT 400 AS status, 'El rol no existe o está inactivo' AS msg;
    ELSE

        -- Validar identificación duplicada
        SELECT COUNT(*) INTO v_existe
        FROM usuarios
        WHERE identificacion = p_identificacion;

        IF v_existe > 0 THEN
            ROLLBACK;
            SELECT 400 AS status, 'La identificación ya está registrada' AS msg;

        ELSE

            -- Validar correo duplicado
            SELECT COUNT(*) INTO v_existe
            FROM usuarios
            WHERE correo = p_correo;

            IF v_existe > 0 THEN
                ROLLBACK;
                SELECT 400 AS status, 'El correo ya está registrado' AS msg;

            ELSE

                INSERT INTO usuarios(
                    id_rol,
                    identificacion,
                    nombre,
                    correo,
                    contrasena
                )
                VALUES(
                    p_id_rol,
                    p_identificacion,
                    p_nombre,
                    p_correo,
                    p_contrasena
                );

                COMMIT;

                SELECT 201 AS status, 'Usuario registrado correctamente' AS msg;

            END IF;

        END IF;

    END IF;

END$$

DELIMITER ;
