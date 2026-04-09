DELIMITER $$

DROP PROCEDURE IF EXISTS sp_actualizar_proveedor$$

CREATE PROCEDURE sp_actualizar_proveedor(
    IN p_identificacion VARCHAR(50),
    IN p_nombre VARCHAR(150),
    IN p_telefono VARCHAR(20),
    IN p_correo VARCHAR(150),
	IN p_direccion VARCHAR(255),
    IN p_activo TINYINT
)
BEGIN

    -- Manejo de errores
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 500 AS status, 'Error interno al actualizar el proveedor' AS msg, 0 AS ok;
    END;

    START TRANSACTION;

	-- Realizar la actualización
    UPDATE proveedores 
    SET nombre = p_nombre,
		telefono = p_telefono,
		correo = p_correo,
		direccion = p_direccion,
		activo = p_activo
	WHERE identificacion = p_identificacion;

	COMMIT;
	SELECT 200 AS status, 'Proveedor actualizado correctamente' AS msg, 1 AS ok;

END$$

DELIMITER ;