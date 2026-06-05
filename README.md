# Projeto 4 — Processamento de Contas Bancárias (COBOL + JCL)

Job batch que lê um arquivo de contas bancárias, **ordena por agência** via `SORT`,
executa um programa **COBOL** para processar os dados e gera um **relatório** com os
dados de cada conta, **subtotais por agência** e os **totais gerais**, além de
**validar** registros inconsistentes.

Desenvolvido e testado no ambiente **TK5 (MVS 3.8j)**, compilador **OS/VS COBOL
(COBOL 74)**. Programa Montreal Acelera Maker — Semana 6.

---

## Estrutura do repositório

```
account-processing/
├── src/
│   ├── ACCTREC.cpy     Copybook do registro de conta (layout fixo, 54 bytes)
│   └── ACCTPROC.cbl    Programa COBOL principal
├── jcl/
│   ├── ACCTSET.jcl     Cria e carrega os arquivos de contas
│   ├── ACCTCOMP.jcl    Compila e linka o programa (gera o load module)
│   └── ACCTRUN.jcl     Ordena por agência, executa o programa e gera o relatório
├── data/
│   ├── ACCOUNTS.txt        12 contas (arquivo principal)
│   └── ACCOUNTS.NEW.txt    4 contas (arquivo novo — adicional #1)
├── img/                Prints de execução (evidências)
├── REPORT.txt          Relatório gerado pela execução
└── README.md
```

---

## Layout da copybook (ACCTREC) — 54 bytes

| Campo         | PIC          | Posição | Tam. |
|---------------|--------------|---------|------|
| ACCT-NUMBER   | 9(08)        | 1–8     | 8    |
| ACCT-NAME     | A(30)        | 9–38    | 30   |
| ACCT-BRANCH   | 9(04)        | 39–42   | 4    |
| ACCT-TYPE     | A(01)        | 43      | 1    |
| ACCT-BALANCE  | S9(09)V99    | 44–54   | 11   |

`ACCT-TYPE`: `C` = conta corrente, `P` = poupança.
A ordenação usa `ACCT-BRANCH` (posição 39, 4 bytes).

> Os nomes seguem o padrão de mercado em inglês; o **layout** (ordem, tipos e
> tamanhos) é idêntico ao especificado no enunciado do projeto.

---

## Ordem de execução

Os três jobs são **rerunnáveis** (apagam e recriam suas saídas). Submeter na ordem:

| # | Job        | O que faz                                                        | Saída |
|---|------------|------------------------------------------------------------------|-------|
| 1 | `ACCTSET`  | Cria e carrega os arquivos de contas                             | `HERC01.ACCOUNTS`, `HERC01.ACCOUNTS.NEW` |
| 2 | `ACCTCOMP` | Compila + linka o programa                                       | `HERC01.LOAD(ACCTPROC)` |
| 3 | `ACCTRUN`  | Concatena os arquivos, ordena por agência, executa e gera o relatório | `HERC01.REPORT` (+ SYSOUT) |

> O `COPY ACCTREC` é resolvido na compilação via `SYSLIB` (`HERC01.COBOL`),
> com a opção `LIB` ativa.

---

## Resultado esperado

| Agência | Contas | Saldo      |
|---------|--------|------------|
| 0001    | 5      | 15.459,50  |
| 0002    | 5      | 29.371,39  |
| 0003    | 4      | 6.415,00   |
| 0004    | 1      | 10.000,00  |
| **Total** | **15** | **61.245,89** |

Mais **1 registro inválido** (conta `00010099`, saldo não-numérico), detectado pela
rotina de validação e excluído dos totais. Total de registros lidos: **16**.

---

## Requisitos atendidos

- [x] Ordenação por agência (SORT)
- [x] Execução do programa COBOL a partir do JCL
- [x] Exibição dos dados das contas
- [x] Total de contas e saldo total
- [x] Copybook do arquivo conforme o layout especificado
- [x] Organização modular (`MAIN-PROCEDURE` + `PERFORM` de parágrafos)
- [x] **Adicional #1** — arquivo extra concatenado antes da ordenação
- [x] **Adicional #2** — subtotal de saldo por agência (control break)
- [x] **Adicional #3** — geração de arquivo de saída (REPORT) além do DISPLAY
- [x] **Adicional #4** — validação de registro com saldo/tipo inválido

---

## Evidências de execução

### 1. Jobs executados com sucesso

Os três jobs (`ACCTSET` -> `ACCTCOMP` -> `ACCTRUN`) executados na ordem,
sem erros (RC=0000):

![Fila de jobs executados](img/Revoult.png)

### 2. Datasets criados no mainframe

Lista de datasets mostrando os arquivos de entrada, a biblioteca de fontes,
a biblioteca de load e o relatório de saída:

![Lista de datasets - DSLIST](img/HER01LIB.png)

### 3. Relatório na SYSOUT (job ACCTRUN)

Saída do programa exibida na SYSOUT do job, agências 0001 e 0002
(com o registro inválido):

![Relatorio SYSOUT - parte 1](img/ACCTRUNJOB00090.png)

Agências 0003 e 0004 e os totais gerais:

![Relatorio SYSOUT - parte 2](img/ACCTRUNJOB00090PARTE2.png)

### 4. Arquivo de saída HERC01.REPORT (adicional #3)

O mesmo relatório gravado no arquivo de saída, parte 1:

![Arquivo REPORT - parte 1](img/Report1.png)

Parte 2, com os totais finais:

![Arquivo REPORT - parte 2](img/Report2.png)

---

## Ambiente

- **Sistema:** TK5 (MVS 3.8j) sob Hercules
- **Emulador 3270:** TN3270 Plus
- **Compilador:** OS/VS COBOL (COBOL 74) — `IKFCBL00`
- **Linkage editor:** `IEWL`
- **Utilitário de sort:** `SORT` (OS/360 Sort/Merge)
- **Transferência de arquivos:** IND$FILE