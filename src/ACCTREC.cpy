       01  ACCOUNT-RECORD.
           05  ACCT-NUMBER     PIC 9(08).
           05  ACCT-NAME       PIC A(30).
           05  ACCT-BRANCH     PIC 9(04).
           05  ACCT-TYPE       PIC A(01).
      *    C = CHECKING | P = SAVINGS
           05  ACCT-BALANCE    PIC S9(09)V99.
