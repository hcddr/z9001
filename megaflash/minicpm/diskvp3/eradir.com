�0�1	�
ERADIR  Vers 1.0  26Aug86
 CP/M directory erase program.
  (c) 1986 by W.Brimhall Znode 52 (602) 996-8739
   (This program can be distributed free for non-commerical use.)

   ERADIR erases the directory of any CP/M 2.2 compatible disk by
   writing E5h to each byte of all sectors in the directory. This
   program must be used with caution since any data that was on the
   drive will be next to impossible to recover. ERADIR is especially
   suited for initalizing RAM disks after power up.

   Command Line Syntax:

	ERADIR /	;Display this help info.
	ERADIR d	;Erase directory on drive "d" (A thru P).
	ERADIR		;Prompt user for drive.

    Information about the selected drive is displayed and you are given
    a chance to abort before the actual directory erase is performed.

 �3�0��su
1u
� }�"�q�1	�
++Must have CP/M vers 2.2 or later... �͜:� �(:� �/��G07�1	�
Logical drive (A: thru P:) ?  ���w
���;~�G���A2K	�P +�1	�++Illegal drive name specified...
 Çͮ���1	�

OK to erase directory on drive  :K	�AͲ�1	�: (y/n, CR=n) ?  ���w
��~�Y��1	�

Erasing directory
 ͓͟u	���1	�Track  *U	���1	� Sector  *Y	���t��0�!O	4:L	��l�;*R	|�(>���1	� Media errors in directory, Reformat and try again...A�1	�
Successful Directory erase
 �1	�
++ERADIR aborted...
 � ��: O���{u
��_�A��Q?�:K	O ��|��^#V#�"d	! ~#fof	 ��!Q	:i	w*k	"O	�@*W	"a	*U	"_	���!u	�6�# ��!  "O	> 2Q	�@�*o	 �	Ҽµx2L	��1	�
Disk information for drive  :K	�AͲ�1	�:
 tracks:	 *_	#���1	�
 sys tracks:	 *s	���1	�
 recs/trk:	 *f	���1	�
 recs/group:	 :i	<o& ���1	�
 tot grps:	 *k	���1	�
 dir entries:	 *m	#���1	�
 dir groups:	 *L	& ����1	�
media error : track  *U	���1	� physical sector  *Y	���;�:Q	<2Q	W:i	�Я2Q	7�*U	DM����*W	��*s	�*U	�
	�`i�&:^	��6+�6*d	���:g	��6g"Y	DM����*O	:h	)=�F:Q	�o�*f	���  �[�*f	�*s		"U	�#"W	ɯ�@�������*R	#"R	ͨ�:K	�aͲ>:Ͳ�*  "�"�"�"�"�"�"�"�"�"�"�"���  �  �  �  �  �  �  �  �  �  �  �  }/o|/g#ɷ|g}o�}�o|�g����BKx��!	!  �.	T]x��.	�$	���"I	��#~�(Ͳ#�7	#��*I	�                                                                                                                                                                                                                                                                                                            �F�                                                                                                                                                                                                           ��2Ez

� !{
~#�o|� g6 :E��w!|
~��w͚w#�j��!|
:{
��͆����� ~#����	���H�ʱ�
ʶ�ʶ�ʺË ËËy�ʋËy�G>�G�O> ͆��Ë�������� ������'���d �
 �}�0͆����� }�o|�g��}�o|�gy��3��3> Æ y�0Æ�>͆>
͆��� ҆� ʆ�ʆ�ʆ�
ʆ�ʆ��>^͆��@͆�����* .	�����������O* .����������a��{��_����� ���������_� �����