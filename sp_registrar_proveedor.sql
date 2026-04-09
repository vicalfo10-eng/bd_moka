DELIMITER $$

DROP PROCEDURE IF EXISTS sp_registrar_proveedor$$

CREATE PROCEDURE sp_registrar_proveedor(
	IN p_identificacion VARCHAR(50),
    IN p_nombre VARCHAR(150),
	IN p_telefono VARCHAR(20),
    IN p_correo VARCHAR(150),
	IN p_direccion VARCHAR(255),
	IN p_activo TINYINT
)
BEGIN

    DECLARE v_existe INT DEFAULT 0;

    -- Manejo de error SQL
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 500 AS status, 'Error interno al registrar el proveedor' AS msg;
    END;

    START TRANSACTION;

    -- Validar identificación duplicada
    SELECT COUNT(*) INTO v_existe
    FROM proveedores
	WHERE identificacion = p_identificacion;

	IF v_existe > 0 THEN
		ROLLBACK;
			SELECT 400 AS status, 'La identificación del proveedor ya está registrada' AS msg;
	ELSE

		INSERT INTO proveedores(
			identificacion,
			nombre,
			telefono,
			correo,
			direccion,
			activo
		)
		VALUES(
			p_identificacion,
			p_nombre,
			p_telefono,
			p_correo,
			p_direccion,
			p_activo
		);

		COMMIT;

		SELECT 201 AS status, 'Proveedor registrado correctamente' AS msg;

	END IF;

END$$

DELIMITER ;
