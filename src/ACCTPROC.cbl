       IDENTIFICATION DIVISION.
       PROGRAM-ID. ACCTPROC.
       AUTHOR. OSIEL.
      *---------------------------------------------------------------*
      * PROJETO 4 - PROCESSAMENTO DE CONTAS BANCARIAS                  *
      * LE O ARQUIVO ORDENADO POR AGENCIA E GERA UM RELATORIO COM:     *
      *   - DADOS DE CADA CONTA                                        *
      *   - SUBTOTAL DE SALDO POR AGENCIA (CONTROL BREAK)              *
      *   - TOTAL DE CONTAS E SALDO TOTAL                              *
      *   - VALIDACAO DE SALDO/TIPO INVALIDO                           *
      * A SAIDA VAI PARA O ARQUIVO REPTOUT E TAMBEM PARA O DISPLAY.    *
      *---------------------------------------------------------------*
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-370.
       OBJECT-COMPUTER. IBM-370.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ACCOUNT-FILE ASSIGN TO UT-S-ACCTIN.
           SELECT REPORT-FILE  ASSIGN TO UT-S-REPTOUT.
      *
       DATA DIVISION.
       FILE SECTION.
       FD  ACCOUNT-FILE
           RECORDING MODE IS F
           LABEL RECORDS ARE STANDARD
           RECORD CONTAINS 54 CHARACTERS.
       01  ACCOUNT-RECORD-IN COPY ACCTREC.
      *
       FD  REPORT-FILE
           RECORDING MODE IS F
           LABEL RECORDS ARE STANDARD
           RECORD CONTAINS 80 CHARACTERS.
       01  REPORT-REC          PIC X(80).
      *
       WORKING-STORAGE SECTION.
       01  WS-CONTROL.
           05  WS-EOF          PIC X(01)      VALUE 'N'.
               88  END-OF-FILE                VALUE 'Y'.
           05  WS-VALID        PIC X(01)      VALUE 'Y'.
           05  WS-PREV-BRANCH  PIC 9(04)      VALUE ZERO.
      *
       01  WS-BRANCH-TOTALS.
           05  WS-BR-ACCTS     PIC 9(05)      VALUE ZERO.
           05  WS-BR-BAL       PIC S9(11)V99  VALUE ZERO.
      *
       01  WS-GRAND-TOTALS.
           05  WS-TOT-ACCTS    PIC 9(05)      VALUE ZERO.
           05  WS-TOT-BAL      PIC S9(11)V99  VALUE ZERO.
           05  WS-INV-ACCTS    PIC 9(05)      VALUE ZERO.
      *
       01  WS-PRINT            PIC X(80).
      *
       01  WS-DETAIL-LINE.
           05  FILLER          PIC X(07)      VALUE 'CONTA: '.
           05  WD-NUM          PIC 9(08).
           05  FILLER          PIC X(06)      VALUE '  AG: '.
           05  WD-BRANCH       PIC 9(04).
           05  FILLER          PIC X(08)      VALUE '  TIPO: '.
           05  WD-TYPE         PIC X(01).
           05  FILLER          PIC X(09)      VALUE '  SALDO: '.
           05  WD-BAL          PIC ZZ,ZZZ,ZZZ,ZZ9.99-.
      *
       01  WS-INVAL-LINE.
           05  FILLER      PIC X(21) VALUE 'REGISTRO INVALIDO  - '.
           05  FILLER          PIC X(07)      VALUE 'CONTA: '.
           05  WI-NUM          PIC 9(08).
           05  FILLER          PIC X(06)      VALUE '  AG: '.
           05  WI-BRANCH       PIC 9(04).
      *
       01  WS-SUB-LINE.
           05  FILLER          PIC X(14)      VALUE '   >> AGENCIA '.
           05  WS-SB           PIC 9(04).
           05  FILLER          PIC X(11)      VALUE '   CONTAS: '.
           05  WS-SB-ACC       PIC ZZZ,ZZ9.
           05  FILLER          PIC X(09)      VALUE '  SALDO: '.
           05  WS-SB-BAL       PIC ZZ,ZZZ,ZZZ,ZZ9.99-.
      *
       01  WS-TOT-LINE.
           05  FILLER      PIC X(20) VALUE 'TOTAL DE CONTAS...: '.
           05  WT-ACCTS        PIC ZZZ,ZZ9.
      *
       01  WS-TOTBAL-LINE.
           05  FILLER      PIC X(20) VALUE 'SALDO TOTAL.......: '.
           05  WT-BAL          PIC Z,ZZZ,ZZZ,ZZZ,ZZ9.99-.
      *
       01  WS-INV-LINE.
           05  FILLER      PIC X(21) VALUE 'REGISTROS INVALIDOS: '.
           05  WV-INV          PIC ZZZ,ZZ9.
      *
       PROCEDURE DIVISION.
       MAIN-PROCEDURE.
           PERFORM OPEN-FILES.
           PERFORM PRINT-HEADER.
           PERFORM READ-RECORD.
           PERFORM INIT-CONTROL.
           PERFORM PROCESS-RECORDS UNTIL END-OF-FILE.
           PERFORM PRINT-BRANCH-TOTAL.
           PERFORM PRINT-GRAND-TOTALS.
           PERFORM CLOSE-FILES.
           STOP RUN.
      *
       OPEN-FILES.
           OPEN INPUT ACCOUNT-FILE OUTPUT REPORT-FILE.
      *
       PRINT-HEADER.
           MOVE '*** RELATORIO DE CONTAS BANCARIAS - PROJETO 4 ***'
               TO WS-PRINT.
           PERFORM PUT-LINE.
           MOVE SPACES TO WS-PRINT.
           PERFORM PUT-LINE.
      *
       READ-RECORD.
           READ ACCOUNT-FILE
               AT END MOVE 'Y' TO WS-EOF.
      *
       INIT-CONTROL.
           IF NOT END-OF-FILE
               MOVE ACCT-BRANCH TO WS-PREV-BRANCH.
      *
       PROCESS-RECORDS.
           IF ACCT-BRANCH NOT = WS-PREV-BRANCH
               PERFORM PRINT-BRANCH-TOTAL
               PERFORM RESET-BRANCH.
           PERFORM VALIDATE-RECORD.
           IF WS-VALID = 'Y'
               PERFORM POST-RECORD
               PERFORM WRITE-ACCOUNT
           ELSE
               PERFORM WRITE-INVALID.
           PERFORM READ-RECORD.
      *
       VALIDATE-RECORD.
           MOVE 'Y' TO WS-VALID.
           IF ACCT-BALANCE IS NOT NUMERIC
               MOVE 'N' TO WS-VALID.
           IF ACCT-TYPE NOT = 'C' AND ACCT-TYPE NOT = 'P'
               MOVE 'N' TO WS-VALID.
      *
       POST-RECORD.
           ADD 1 TO WS-BR-ACCTS.
           ADD 1 TO WS-TOT-ACCTS.
           ADD ACCT-BALANCE TO WS-BR-BAL.
           ADD ACCT-BALANCE TO WS-TOT-BAL.
      *
       WRITE-ACCOUNT.
           MOVE ACCT-NUMBER  TO WD-NUM.
           MOVE ACCT-BRANCH  TO WD-BRANCH.
           MOVE ACCT-TYPE    TO WD-TYPE.
           MOVE ACCT-BALANCE TO WD-BAL.
           MOVE WS-DETAIL-LINE TO WS-PRINT.
           PERFORM PUT-LINE.
      *
       WRITE-INVALID.
           ADD 1 TO WS-INV-ACCTS.
           MOVE ACCT-NUMBER TO WI-NUM.
           MOVE ACCT-BRANCH TO WI-BRANCH.
           MOVE WS-INVAL-LINE TO WS-PRINT.
           PERFORM PUT-LINE.
      *
       PRINT-BRANCH-TOTAL.
           MOVE WS-PREV-BRANCH TO WS-SB.
           MOVE WS-BR-ACCTS    TO WS-SB-ACC.
           MOVE WS-BR-BAL      TO WS-SB-BAL.
           MOVE WS-SUB-LINE    TO WS-PRINT.
           PERFORM PUT-LINE.
           MOVE SPACES TO WS-PRINT.
           PERFORM PUT-LINE.
      *
       RESET-BRANCH.
           MOVE ZERO TO WS-BR-ACCTS.
           MOVE ZERO TO WS-BR-BAL.
           MOVE ACCT-BRANCH TO WS-PREV-BRANCH.
      *
       PRINT-GRAND-TOTALS.
           MOVE SPACES TO WS-PRINT.
           PERFORM PUT-LINE.
           MOVE WS-TOT-ACCTS TO WT-ACCTS.
           MOVE WS-TOT-LINE  TO WS-PRINT.
           PERFORM PUT-LINE.
           MOVE WS-TOT-BAL   TO WT-BAL.
           MOVE WS-TOTBAL-LINE TO WS-PRINT.
           PERFORM PUT-LINE.
           MOVE WS-INV-ACCTS TO WV-INV.
           MOVE WS-INV-LINE  TO WS-PRINT.
           PERFORM PUT-LINE.
      *
       PUT-LINE.
           DISPLAY WS-PRINT.
           WRITE REPORT-REC FROM WS-PRINT.
      *
       CLOSE-FILES.
           CLOSE ACCOUNT-FILE REPORT-FILE.
