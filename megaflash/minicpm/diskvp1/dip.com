1M�  copyright (c) 1982, 1983, 1984, ice corp 1M� �x�                                                                                                                                                                                                    �A2j:� 2i��Kb
�d�0�	�d >~�l!� ~��P#O�o6 .�~�a�F�{�F�_w#�8�2e2f2g!� l �\��=�	�C\ �\��ʪ�[�	�C��]ʪ�Qʞ�Pʤ�V�	�C2f�~2e�~2g�~!�"_l !�w#¸�22k!\ �%	�*!��%	�**_"a"c:	O:	���>2g!�~� �6?#�] !��?�%��%7	�C#��/�2h\ � ����C�����ƀo& "]�\͢� ���A:h�p	�C�n�/*_"M*a~�t###��¡�F�<�C~	�d:	O�����Rë�F<��Ì*M� �* ͭ�����*M��x���U���*a#4��#4*M� "Më*_��+++0 p	"aͭ�t*_"O�=�7:k��1�2�2x<2kl�Pl�_�<�C�7l�F:f��Pl͖*c#^#V�*O�*c#~5#G�ʃx��b5*O��xl�Z���C*O� "O�P+4:f���� �xl͑�"O�}���+�l�U*O� ����#²"OÜ�	�Cl�K!�<�C*c~��:�2k*c$ 	|~#��|�Pl͂�<�C:	O!|���	�d*_�*c0 	"cͭ�@*M�*Oͭ�	�E�k��d:i��P�A	�d�i�  *_�w#w#w#�:\ *]#~�p�#p	p#�
w�*]>#�
�?~�=�"_�:e���*_���$ :	O��=�}��###:	O���	�d�i�:R���:S�Y���y��"_�>�2h�y#��A_�}:�}��~� ��.�}�~#� �%��_�}���� �K	�K	�2	�K	�@�y��g=ʝ=��~#�Z�Z�N#6�#�͛ ^#V�s#r#�ͨ ~O/_#~G/W�s#r#��E��s#r��~�¬�͇���A����
�d�i͇��N�7�͌�����^ͣ�#~�6 ��+���#��������G
�d�>2gÝ##^#V#N#F#�^#V��:g��^ 	MD���	�d��d�	�d�{�A_�}	
�d�i�*_]T	"_�}D��}
�}��> �d�G�n���� �w�*���.��:����:°x���@G> �w���*���:��.���í>?���í{�_���:��.��*�����>?�����> ��~#���=��[�+33����	�C~#� ��~6 �(	�C��:j�! �)�;� � � � � � � 	� Q
� 
� � � � � %� !� $�  * �� � }�|��No Source File$No Directory Space$Out of Data Space$Write Protected?$Copy Complete$        Source$        Destination$Illegal Device$File Mask$
Load System Disk on Drive A:, then Type (cr)$No More Files$Loading $ Created
$ (y/n) ? $"=" Expected$Illegal Separator$
*$Verify: Bad Sector$Illegal Switch$File Spec Error$
Load $ Disk on Drive $:, then Type (cr)$
Load Any Disk on Drive A:, then Type <cr>$
Wrong Disk, Try Another!$
          Disk Interchange Program - ver 2.2
             @ copyright ICE APP - 1984

Syntax:
    Destination = Source

    DIP d:filespec = d:[options]
    DIP d: = filespec[options]
    DIP d:filespec = d:filespec[options]
    DIP<cr>
    *
Purpose:
    DIP copies files between diskettes, like PIP,
    but with a different set of options. It works
    with only one drive, if you need this.
DIP Options:
      Q   Querry user for each file transfer
      P   Prompt user for each disk change
      V   Verify that data has been written o.k.
Example:
    COPY ONE DISK TO ANOTHER USING ONLY DRIVE A:
      A>DIP A:=*.*[PQV]
$                                                                                             F     
                           DIP     $$$                                                                                                                                        