% this test script is for the mgds framework:


mgds = MGDS('My_first_gds');
mgds.bDeleteFlag = false;

mgds.makeStructure({'main', 'atom', 'array'});


mgds.makeShape('atom', [0 1 1 0], [0 0 1 1], 3);
mgds.makeShape('atom', 3 + [0 1 1 0], 4 + 2*[0 0 1 1], 1);

mgds.makeRef('main', 'atom', [0 0; 10 10]);

mgds.makeARef('array', 'atom', 10, 10, 20, 20, -110, -110);


mgds.makeGDS();


