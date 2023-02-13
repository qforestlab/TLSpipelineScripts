import open3d as o3d
import sys
import os
import glob
import numpy as np

def main(args):
    if len(args) < 2:
        print("provide directory containing your tiled ply files")
        return
    
    dir = args[1]

    if not os.path.isdir(dir):
        print("File not found")
        return

    tile_index_f = "t_index.dat"
    
    for file in glob.iglob(f'{dir}/*.ply'):
        print(file)
        pcd = o3d.io.read_point_cloud(file)
        # get center
        center = pcd.get_center()
        T = int(os.path.basename(file).split('.')[0])
        with open(dir+tile_index_f, 'a') as f:
            f.write(f'{T} {center[0]} {center[1]}\n')

    print("tile index file to be used in TLS2trees algo was created at t_index.dat")
    return


if __name__ == "__main__":
    main(sys.argv)