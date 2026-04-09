DELIMITER $$

DROP PROCEDURE IF EXISTS sp_registrar_categoria$$

CREATE PROCEDURE sp_registrar_categoria(
    IN p_nombre VARCHAR(100),
    IN p_descripcion VARCHAR(255),
    IN p_activo TINYINT
)
BEGIN

    DECLARE v_existe INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 500 AS status, 'Error interno al registrar la categoría' AS msg, 0 AS ok;
    END;

    START TRANSACTION;

    -- Validar si ya existe una categoría con el mismo nombre
    SELECT COUNT(*) INTO v_existe
	FROM categorias
	WHERE nombre = p_nombre;

    IF v_existe > 0 THEN
        SELECT 400 AS status, 'Ya existe una categoría con ese nombre' AS msg, 0 AS ok;
		
    ELSE
	
        INSERT INTO categorias(
			nombre,
			descripcion,
			activo
		)
        VALUES(
			p_nombre,
			p_descripcion,
			p_activo
		);

        COMMIT;
		
        SELECT 201 AS status, 'Categoría registrada correctamente' AS msg, 1 AS ok;
		
    END IF;
	
END$$