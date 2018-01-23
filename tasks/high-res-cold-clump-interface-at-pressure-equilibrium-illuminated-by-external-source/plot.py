import yt, os, re

attrs = [('Pressure', 1e-7, 1e-5, True),
         ('density', 1e-4, 1, True),
         ('Pres_IR', 1e3, 1e6, True),
         ('HII', 1e-7, 1e-5, True),
         ('temp_IR', -100, 100, False)]

outputs = [d for d in os.listdir('./..') if re.match(r'output_.*', d)]

for i, output in enumerate(outputs):
    if (i % 50 != 0): continue
    ds = yt.load('./../' + output +'/info_' + output[7:] +'.txt')
    for attr in attrs:
        p = yt.SlicePlot(ds, 'z', attr[0])
        p.set_zlim(attr[0], attr[1], attr[2])
        p.set_log(attr[0], attr[3])
        p.save()
        p = yt.ProjectionPlot(ds, 'z', attr[0])
        p.set_zlim(attr[0], attr[1], attr[2])
        p.set_log(attr[0], attr[3])
        p.save()
