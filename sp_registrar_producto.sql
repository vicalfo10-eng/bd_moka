DELIMITER $$

DROP PROCEDURE IF EXISTS sp_registrar_producto$$

CREATE PROCEDURE sp_registrar_producto(
	IN p_categoria INTEGER,
	IN p_proveedor INTEGER,
	IN p_codigo VARCHAR(50),
    IN p_nombre VARCHAR(150),
	IN p_precio DECIMAL(10,2),
	IN p_impuesto DECIMAL(5,2),
    IN p_stock INTEGER,
	IN p_stockmin INTEGER,
	IN p_activo TINYINT
)
BEGIN

    DECLARE v_existe INT DEFAULT 0;

    -- Manejo de error SQL
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 500 AS status, 'Error interno al registrar el producto' AS msg;
    END;

    START TRANSACTION;

    -- Validar identificación duplicada
    SELECT COUNT(*) INTO v_existe
    FROM productos
	WHERE codigo = p_codigo;

	IF v_existe > 0 THEN
		ROLLBACK;
			SELECT 400 AS status, 'El código del producto ya está registrado' AS msg;
	ELSE

		INSERT INTO productos(
			id_categoria,
			id_proveedor,
			codigo,
			nombre,
			precio,
			impuesto,
			stock,
			stock_minimo,
			activo
		)
		VALUES(
			p_categoria,
			p_proveedor,
			p_codigo,
			p_nombre,
			p_precio,
			p_impuesto,
			p_stock,
			p_stockmin,
			p_activo
		);

		COMMIT;

		SELECT 201 AS status, 'Producto registrado correctamente' AS msg;

	END IF;

END$$

DELIMITER ;