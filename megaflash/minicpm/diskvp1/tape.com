   !� ��R��! ���  : ˇˏ2 ۈ˗ӈ!x�#{�$ ���40����(�!2�#{�$ �!] ��(��* >?w#�1�.(� +�˯wx� (#��x� (6  �#�.�����* >?w#�� +�˯w#x�  �!>�#{�$ �!] � ���   �S� > 2\ \ � �� !��#{�$ ��l�! � (  =�">���#= �.�>���#= �!A�#{�$ ���˯�J(�N(W���  \ *+��*� ��> 22| �[� \ � *� "�!4�(�!] � ��!�]  ������!  � ��!�� ��\ !� ��!q 6���!  " � *�� �S ��"��G:� �����!2�#{�$ �!\ ����.(�* >?w#�+� +�wx� (#��x� (6  �#�.�����* >?w#�� +�w#x�  �!>�#{�$ �> 22l !�" !  "�'!�^> �  �#�.�^�#�:	� (!��#{�$ ��l�!A�#{�$ ���˯�J(�N(����!�\  ��!_�#{�$ ����!�" � �[���S!4�� �!\ � ��> 2\ 2| ] !� ��� \ � ��(!��#{�$ ��l�\ � �8!��#{�$ ��l�!  "*� � ��"\ � �(!��#{�$ ��l�:G:| � �\ � �8!��#{�$ ��l��^{�$����� ����͓��2l �4���S !\ �E>7���> 2	��~�?(�!0�!8�(>2	#������ � ��              Kopier-Programm
              ---------------




       1 - Kassette --> Diskette



       2 - Diskette --> Kassette



       3 - Ende




              Eingabe :$
Filename:$
$  Kopieren ?    (J/N/STOP) 
$Kassette zur}ck an Programmanfang
und starten
$
Datei vorhanden !$
Directory voll !$
Schreibfehler !$
Datei nicht gefunden !$
falscher Dateiname !$           d starten
$
Datei vorhanden !$
Directory voll !$
Schreibfehler !$
Datei nicht gefunden !$
fa2:	ld	m,a
	inc	hl
	djnz	dl62
	jr	dl7a
dl61:	cp	8	;Fehler
	jr	nz,dl7	;nein
	dec	hl
	inc	b
	jr	dl6
dl7:	res	5,a
	ld	m,a	!  " � *�� �S ��"��G:� �����!2�#{�$ �!\ ����.(�* >?w#�+� +�wx� (#��x� (6 