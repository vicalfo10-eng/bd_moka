DELIMITER $$

DROP PROCEDURE IF EXISTS sp_obtener_categoria$$

CREATE PROCEDURE sp_obtener_categoria(
    IN p_id_categoria INT
)
BEGIN

    DECLARE v_existe INT DEFAULT 0;

    SELECT COUNT(*) INTO v_existe
	FROM categorias
	WHERE id_categoria = p_id_categoria;

    IF v_existe > 0 THEN
	
        SELECT *, 200 AS status, 'Categoría encontrada' AS msg, 1 AS ok 
        FROM categorias 
        WHERE id_categoria = p_id_categoria;
		
    ELSE
	
        SELECT 404 AS status, 'Categoría no encontrada' AS msg, 0 AS ok;
		
    END IF;
	
END$$

DELIMITER ;