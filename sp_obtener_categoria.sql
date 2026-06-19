DELIMITER $$

DROP PROCEDURE IF EXISTS sp_obtener_categoria$$

CREATE PROCEDURE sp_obtener_categoria(
    IN p_filtro VARCHAR(100)
)
BEGIN

    IF p_filtro IS NULL OR TRIM(p_filtro) = '' THEN

        SELECT
            *,
            200 AS status,
            'Categorías obtenidas' AS msg,
            1 AS ok 
        FROM categorias;

    ELSE
        
        SELECT
            *,
            200 AS status,
            'Resultados obtenidos' AS msg,
            1 AS ok 
        FROM categorias 
        WHERE ( p_filtro REGEXP '^[0-9]+$' AND id_categoria = CAST(p_filtro AS UNSIGNED) )
           OR nombre LIKE CONCAT('%', p_filtro, '%');

    END IF;
    
END$$

DELIMITER ;