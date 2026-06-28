 main:
loadn r0, #10;
loadn r1, #'A';
outchar r1,r0;
loadn r2, #0;
loadn r3, #500;
loadn r4, #600;
sound r3,r4,r2; //r2 = tipo de onda , r3 = frequencia, r4 = tempo que toca
halt;

