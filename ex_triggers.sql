USE MASTER
GO
DROP DATABASE IF EXISTS ex_triggers_07
GO
CREATE DATABASE ex_triggers_07
GO
USE ex_triggers_07
GO
/*
- Uma empresa vende produtos alimentícios
- A empresa dá pontos, para seus clientes, que podem ser revertidos em prêmios
- Para não prejudicar a tabela venda, nenhum produto pode ser deletado, mesmo que não venha mais a ser vendido
- Para não prejudicar os relatórios e a contabilidade, a tabela venda não pode ser alterada. 
- Ao invés de alterar a tabela venda deve-se exibir uma tabela com o nome do último cliente que comprou e o valor da 
  última compra
- Após a inserção de cada linha na tabela venda, 10% do total deverá ser transformado em pontos.
- Se o cliente ainda não estiver na tabela de pontos, deve ser inserido automaticamente após sua primeira compra
- Se o cliente atingir 1 ponto, deve receber uma mensagem (PRINT SQL Server) dizendo que ganhou
*/
CREATE TABLE cliente (
codigo		INT			NOT NULL,
nome		VARCHAR(70)	NOT NULL
PRIMARY KEY(codigo)
)
GO
CREATE TABLE venda (
codigo_venda	INT				NOT NULL,
codigo_cliente	INT				NOT NULL,
valor_total		DECIMAL(7,2)	NOT NULL
PRIMARY KEY (codigo_venda)
FOREIGN KEY (codigo_cliente) REFERENCES cliente(codigo)
)
GO
CREATE TABLE pontos (
codigo_cliente	INT					NOT NULL,
total_pontos	DECIMAL(4,1)		NOT NULL
PRIMARY KEY (codigo_cliente)
FOREIGN KEY (codigo_cliente) REFERENCES cliente(codigo)
)
GO
CREATE TABLE ultima_compra (
codigo_cliente	INT				NOT NULL,
valor_compra	DECIMAL(7,2)	NOT NULL
PRIMARY KEY (codigo_cliente)
FOREIGN KEY (codigo_cliente) REFERENCES cliente(codigo)
)
GO

CREATE TRIGGER tr_ins_venda
ON venda
AFTER INSERT
AS
BEGIN
    -- atualiza a tabela de pontos com os pontos da nova venda
    DECLARE @codigo_cliente INT
    DECLARE @valor_total DECIMAL(7,2)
    DECLARE @total_pontos DECIMAL(4,1)

    SELECT @codigo_cliente = inserted.codigo_cliente, @valor_total = inserted.valor_total
    FROM inserted

    -- atualiza os pontos do cliente
    IF EXISTS (SELECT * FROM pontos WHERE codigo_cliente = @codigo_cliente)
    BEGIN
        SELECT @total_pontos = total_pontos FROM pontos WHERE codigo_cliente = @codigo_cliente
        UPDATE pontos SET total_pontos = @total_pontos + (@valor_total * 0.1) WHERE codigo_cliente = @codigo_cliente
    END
    ELSE
    BEGIN
        INSERT INTO pontos (codigo_cliente, total_pontos) VALUES (@codigo_cliente, @valor_total * 0.1)
    END

    -- atualiza a tabela de última compra
    UPDATE ultima_compra SET valor_compra = @valor_total
    WHERE codigo_cliente = @codigo_cliente

    IF @@ROWCOUNT = 0 -- se não houver registro na tabela, insere um novo
    BEGIN
        INSERT INTO ultima_compra (codigo_cliente, valor_compra) VALUES (@codigo_cliente, @valor_total)
    END
END
GO

CREATE TRIGGER tr_ins_cliente
ON cliente
AFTER INSERT
AS
BEGIN
    -- insere o novo cliente na tabela de pontos
    DECLARE @codigo_cliente INT

    SELECT @codigo_cliente = inserted.codigo
    FROM inserted

    INSERT INTO pontos (codigo_cliente, total_pontos) VALUES (@codigo_cliente, 0)
END
GO

CREATE TRIGGER tr_upd_pontos
ON pontos
AFTER UPDATE
AS
BEGIN
    -- verifica se o cliente atingiu 1 ponto
    DECLARE @codigo_cliente INT
    DECLARE @total_pontos DECIMAL(4,1)

    SELECT @codigo_cliente = inserted.codigo_cliente, @total_pontos = inserted.total_pontos
    FROM inserted

    IF (@total_pontos >= 1)
    BEGIN
        PRINT 'O cliente ' + CAST(@codigo_cliente AS VARCHAR(10)) + ' ganhou 1 ponto!'
    END
END
GO