   1 �>2Q>2R!S:IO�8>D��:F��2U:N!J� ������(��!R5>T��������!JV ��45���>�w#>
w:M�>� >�2\:F�O ?�W ͚��w>W��͓�(�T(��C ?!F�F 8!Q5(2�!F�v((�V($˖��+!cK ��� !J:b�(45�Fw������Q�Q�nG�����n�h(�>��>F�`�>R��Q�n�4�:OG:J(�2V�Q����[]����o 
 � �>R> ѷ�!T�g����� �y�#N�������g͍���n!_w��O�n#w�y���0�������S��<2T�4�!� :M�G()�:NG  ��}��G�($D�*G� !���	:TO��Q��x�������� ������w���>R�y��>B�:`O�9>U��9>W��9>S��9�9>C��9�>S��4�
�<O�Q��:F���              F   ���       d*  Pr    	
	Spur: $  Kopf: $Formatierung von CP/M-Disketten
      fuer CP/M-Z9001
(c) 1989 F.Schwarzenberg  Version 2.0
zu formatierende Diskette
erst nach Aufforderung einlegen!

Laufwerk ([A|B] Enter=A) $
Diskette in Laufwerk A: einlegen!
Diskette wird geloescht
([j|v]/n)(v: mit Verify)? $Formate fuer LW-Typ 80 Spuren DS (1.6)

0= 800K 4= 400K (80SS) 8= 200K (40SS)
1= 780K 5= 400K (40DS) 9= 148K (40SS)
2= 720K*6= 360K*(40DS)
3= 624K 7= 308K (80SS)
* -> IBM-PC-Format mit Bootblock
Welches Format? $ Formate fuer LW-Typ 80 Spuren SS (1.4)

0= 400K (80SS)     2= 200K
1= 308K (80SS)     3= 148K

Welches Format? $ Formate fuer LW-Typ 40 Spuren DS�
0= 400K (40DS)     2= 200k (40SS)
1= 360K ( IBM)     3= 148  (40SS)

Welches Format? $ Formate fuer LW-Typ 40 Spuren SS (1.2)�
0= 200k      1= 148K

Welches Format? $ 
 �d  Pr �d Pr	*�P* Pw �2 P� �d   Pr �d  (r	*�P* (w �2  P� �d   (r �2  (� �d   Pr �2  P� �d   (r �2  (� �d  (r	*�P* (w �d   (r �2  (� �d   (r �2  (�� �
� ��� ��!��(G��'�w>3�g#w�	�   $               $�2U2q2b>2S�	� ���_�(��  �(��A8��0�2�2U� 2p:��A2o � :��(3 	 	:��# >P�(>(�6��##~/��2n!���(=!N�(=!(!���	� ���0���
8�_����2o�2:p_� :n����	:o�	>:o�(�	� 
>32>62%�[p� !! 6 ��� < �	� � �(@� ���� �SG� �2*G� 	"G�� � !4�(�5� �#:oG������O 	Y ��f ��:j2O:k2�
:h2X	� � �_�J(
�V�>�2q����:f2[���o�2W2J����	� ��� � :W��(�� ���
�:q�(G:W2K��82F!/"G:Z2N:Y2M>2L:�2I�	�:N2Z�2b (S	� :% �ʈ
:JO:i�(
:W�2W y�P��	����:�(<!/!"G>|2F:�2I�2J2K<2L<2M:�?�?2N�	��  2��	� :b��  d	� �  �*l�:Z��� O!�	:ZO:Yw+�~ w+:Ww+:Jw�#+ �:J� >�0>Sw+:[w+:Zw+:Yw+:U�G:W�w+M�T�Z������W�o�o�  :Z��G�0���� ���R(2��	� �	� �  Bootblockdatei nicht vorhanden oder fehlerhaft!
Diskette einlegen!(ESC=ohne Bootblock): $Schreibfehler! " "
fehlerhafter DOS-Bootblock!$ Systemfehler (falsches System)!
$falsche Laufwerk-Parameter
$  Lese-Fehler:  $Fehler beim Formatieren!
 Verwenden Sie POWER (TEST)
 zum Ueberpruefen der Diskette$Drive not ready
$    : ERROR$ ʶ1�ʛ6â6��"%@��;:͞:���!���*#@��*	@�*�?�!��!�6 BOOT720 DAT@"@�͍�7:@���6x��7r Diskette$Drive not ready
$    : ERROR$ ʶ1�ʛ6â6��"%@��;:͞:���!���*#@��*	@�