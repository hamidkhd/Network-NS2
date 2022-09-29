import os
import matplotlib.pyplot as plt
import numpy as np
from termcolor import colored

LEGEND1 = 'n1 to n5'
LEGEND2 = 'n2 to n6'

TCP_TYPES = ['reno', 'cubic', 'yeah']

def run_ns():
    print(colored('tracefiles will be saved in ./output/', 'yellow'))
    for t in TCP_TYPES:
        print(colored(f'running {t}.tcl ...', 'green'))
        os.system(f'ns {t}.tcl')


def read_drop_data(tcp_type):
    f = open(f'output/{tcp_type}Trace.tr', 'r')
    drops = []
    for line in f.readlines():
        line = line.split()
        if line[0] == 'd':
            drops.append(line)
    
    data = {}
    for d in drops:
        t = int(float(d[1]))
        fid = int(d[7])
        if t not in data:
            data[t] = [t,0,0]
        data[t][fid] += 1
        
    data = [v for v in data.values()]
    
    return np.array(data)


def read_plot_data(tcp_type, data_type):
    if data_type == 'drop':
        return read_drop_data(tcp_type)

    
    f = open(f'output/{tcp_type}_{data_type}.tr', 'r')
    data = [] 

    for line in f.readlines():
        data.append([float(i) for i in line.split()])

    return np.array(data)



def plot_data(ax, plot_type):
    print(colored(f'plotting {plot_type}...', 'blue'))
    ax.set_title(plot_type.upper())
    ax.set_xlabel('time')
    ax.set_ylabel(plot_type)
    for t in TCP_TYPES:
        cwnd_data = read_plot_data(t, plot_type)
        ax.plot(cwnd_data[:,0], cwnd_data[:,1], label=f'{t} {LEGEND1}')
        ax.plot(cwnd_data[:,0], cwnd_data[:,2], label=f'{t} {LEGEND2}')
    
    ax.legend(loc='best')




run_ns()

cwnd_fig, cwnd_ax = plt.subplots()
gp_fig, gp_ax = plt.subplots(figsize=(20,10))
rtt_fig, rtt_ax = plt.subplots()
drop_fig, drop_ax = plt.subplots(figsize=(8,8))

plot_data(gp_ax, 'goodput')
plot_data(cwnd_ax, 'cwnd')
plot_data(rtt_ax, 'rtt')
rtt_ax.legend(loc='upper right')
plot_data(drop_ax, 'drop')

# plt.show()

cwnd_fig.savefig('plots/cwnd_fig.png')
gp_fig.savefig('plots/gp_fig.png')
rtt_fig.savefig('plots/rtt_fig.png')
drop_fig.savefig('plots/drop_fig.png')

print(colored('plots are saved in ./plots/', 'yellow'))



