import os
 
if __name__ == "__main__":
   file_list = []
   path = './scale'
   path1 = 'F:/Project/WorkSpace/FPGA/Video_pro/Source/Processor'
 
   for root, directory, files in os.walk(path):
      for file in files:
         if file[-2:] == ".v" or file[-3:] == ".vp":
            file_list.append(root.replace('\\', '/')+'/'+file)
 
   with open('./sim_src_list.f', 'w') as f:
      for file in file_list:
         # f.write("{:s}\n".format(file))
         f.write(path1+file+'\n')
         # file.replace("./../..","F:/Project/WorkSpace/FPGA/MES50HP/07_ddr3_test/ipcore/ddr3_test")