CAMEL80 COM �    �    � � � � � P         18BF 300 � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � �CFORTH    *6 %�$���%%��� Ä   EXIT�^ �#�V �#�^#V#��$ LIT�OG�^#V#��= EXECUTE`i���+�r �+�s �^#V#��R VARIABLE�^�A m
�)��DM�^#V#��r CONSTANT�^�"��N#F�^#V#�� USER�^�"��N#F���	DM�^#V#���+�r �+�s ���DM�^#V#�� BDOS�������� O ������^#V#��� EMIT�^A ��) KEY?�^A �Y)( KEY�^A �)= 	CPMACCEPT�^�A <��A
 ����A
 )O BYE�  � DUP��^#V#�� ?DUPx� ��^#V#�� DROP��^#V#�� SWAP��DM�^#V#�� OVER���DM�^#V#��� ROT���DM�^#V#��� NIP�^��)� TUCK�^��) >R�+�p �+�q ��^#V#�� R>��N �#�F �#�^#V#��0 R@��N �F�^#V#��H SP@�!  9DM�^#V#��\ SP!`i���^#V#��q RP@�����^#V#�� RP!�����^#V#�� !`i�q#p��^#V#�� C!`i�q��^#V#�� @`iN#F�^#V#��� C@
O �^#V#��� PC!��i��^#V#��� PC@�H �^#V#��  +�	DM�^#V#�� M+���	BK0���^#V#��" -��BDM�^#V#��: AND�x�Gy�O�^#V#��L OR�x�Gy�O�^#V#��a XOR�x�Gy�O�^#V#��u INVERTx/Gy/O�^#V#�� NEGATEx/Gy/O�^#V#�� 1+�^#V#�� 1-�^#V#��� ><xAO�^#V#��� 2*�!��^#V#��� 2/�(��^#V#��� LSHIFTA�)�DM�^#V#�� RSHIFTA��<��DM�^#V#��" +!�
�
���^#V#��@ 0=x���GO�^#V#��V 0<� �GO�^#V#��j =��B((  �^#V#��| <>�^~Y)� <��B�����^#V#����� >�^��)� U<��B�GO�^#V#��� U>�^��)� BRANCHog^#V#��� ?BRANCHx��(��^#V#�� (DO)���! ���R�+�t �+�u 	�+�t �+�u ���^#V#�� (LOOP)� �n �f��J�l�u �t�� �	��^#V#��L (+LOOP)��DM���~ I��n �f�N�F��BDM�^#V#�� J��n�f�N�F��BDM�^#V#�� UNLOOP�#�#�#�#�^#V#��� UM*����!  >�����0	= ������^#V#��� UM/MOD�����>�#��j0��B��B0	7��= �z/G{/O�����^#V#��	 FILLy��ѷ!���J0	(bk�����^#V#��M	 CMOVE�����x�(�����^#V#��s	 CMOVE>�����x�(	+�	+�����^#V#��	 SKIPy���_x�({�� ��	+�����^#V#��	 SCANy���_x�({�� +�����^#V#���	 S=�����x�(	�� 	�

�  +���G�O�^#V#���	 ALIGN�^#V#��+
 ALIGNED�;
 CELLͪ H
 CELL+�^#V#��U
 CELLS��g
 CHAR+üs
 CHARS�
 >BODY�^A )�
 COMPILE,��
 !CF�^A� ����)�
 ,CF�^��
A �)�
 !COLON�^A���A^�
)�
 ,EXIT�^A)�
)�
 ,BRANCH�
 ,DEST� !DESTé$ BLͪ  0 TIBSIZEͪ| ; TIBͪ� K U0��  W >IN�� b BASE�� n STATE�� { DP�� � 'SOURCE��
 � LATEST�� � HP�� � LP�� � S0�� � PAD��(� L0���� R0�� � UINIT͊    
   �      � #INITͪ  S>D�^�m)" ?NEGATE�^mE�)2 ABS�^�:)J DNEGATE�^����A %)Z ?DNEGATE�^m�b)x DABS�^��)� M*�^�y�N�N�3�)� SM/REM�^�y�N�3	�3:�3:)� FM/MOD�^���m�3���3�)� *�^��) /MOD�^&3�)- /�^2�)B MOD�^2�)P */MOD�^�3�)` */�^f�)v MAX�^�����)� MIN�^�����)� 2@�^�[
���)� 2!�^���[
�)� 2DROP�^��)� 2DUP�^��)� 2SWAP�^��3) 2OVER�^�33) COUNT�^�y
��)2 CR�^A A
 )H SPACE�^3)_ SPACES�^��e��{�)q UMIN�^�����)� UMAX�^�����)� ACCEPT�^���A�A ���A ~���3������������<)� TYPE�^�A��"��S3�C�) (S")�^38�C
)HS"�^AM�
A" ���C
�)a."�^dA"�
)� UD/MOD�^A  K	��3	�)� UD*�^����3��)� HOLD�^A���C���)� <#�^���)� >DIGIT�^�A	 �A PA0 )  #�^s����)% #S�^'�dYA); #>�^�����<)R SIGN�^m}A- �)i U.�^�A  >U"e)� .�^��NA  >�nU"e)� DECIMAL�^A
 s�)� HEX�^A s�)� HERE�^��)� ALLOT�^�C)� ,�^��A m
�)
 C,�^��A �
�)  SOURCE�^��)7 /STRING�^����<)J >COUNTED�^��y
�y	)f WORD�^�>f�R���	���	���33�<fC<�o�3�8�)� NFA>LFA�^A <)� NFA>CFA�^8A P)� IMMED?�^��)  FIND�^�����y

�7����Y�U����YA d)LITERAL�^��uAA�
)Z DIGIT?�^�A9 �A P�A@�AP<A0 <�s��)z ?SIGN�^��A, <�NA ~P���A R3)� >NUMBER�^�(���Y�)s��3%A R��)� ?NUMBER�^�A  ��8��\3��A  �l��3h�A��)- 	INTERPRET�^��A  f�3���������Yd�Z���
��5�b��8"A? KS���)q EVALUATE�^��f�{3f�33��)� QUIT�^�����A  ��O�CYe{��YFKMok "�& ABORT�^�uM ?ABORT�^�s"S�)_ABORT"�^dAf�
)z '�^3�YM?f)� CHAR�^3���)�[CHAR]�^�AA�
)�(�^A) ��)� CREATE�^��A  #���3����A��
)� (DOES>)�^3����
)DOES>�^A"�
A��
)4RECURSE�^����
)N[�^A  ��)f ]�^A����)x HIDE�^����A� d��)� REVEAL�^����A P��)� 	IMMEDIATE�^A ����)� :�^��z�
)�;�^��
h)�[']�^�AA�
)
POSTPONE�^3��YM?fmTAA�
A�
�
�V�
) IF�^A��)[THEN�^��*)rELSE�^A����w)�BEGIN���UNTIL�^A)�AGAIN�^A�)�WHILE�^�REPEAT�^��w)� >L�^M
�C���)� L>�^���M
��C)DO�^A"�
�A  �)+ ENDLOOP�^�aw�S)DLOOP�^ASL)f+LOOP�^A�L)yLEAVE�^A��
A����)� WITHIN�^�<<3�)� MOVE�^���K��3�	��3y	)� DEPTH�^`��<�)� ENVIRONMENT?�^�A  ) WORDS�^���8"e���Y5�)( .S�^`�<z`�A <"���A���l)P COLD�^�Zy	M#Z80 CamelForth v1.01  25 Jan 1995
"S � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � 