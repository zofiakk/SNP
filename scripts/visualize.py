import argparse
import matplotlib.pyplot as plt
import seaborn as sns
import pandas as pd
import yaml


VARIANTS = ('SNPs', 'Indels')
SNS_STYLE = 'whitegrid'

COLORS = {'fill': {'SNPs': 'mediumturquoise', 
                   'Indels': 'lightcoral'},
          'vline': {'SNPs': 'mediumturquoise', 
                    'Indels': 'lightcoral'}}

sns.set_style(SNS_STYLE)


def parse_arguments():
    """Read arguments from a command line."""
    desc = 'Script for generating visualisations'
    parser = argparse.ArgumentParser(description=desc)
    parser.add_argument("-s", '--snps_file', required=True,
        help='Input file with SNPs in VCF format.')
    parser.add_argument("-i", '--indels_file', required=True,
        help='Input file with indels in VCF format.')
    parser.add_argument("-c", '--config_file', required=True,
        help='Configuration file (YAML) containing values used to filter data.')
    parser.add_argument("-o", '--output', default='output.png',
        help='Output file')
    parser.add_argument("-f", '--fmt', default='png',
        help='Format of the output file: png (default), svg, jpg.')
    parser.add_argument("-a", '--all', default=True,
        help='Plot all available variables (default) vs only the ones with defined filter values.')

    args = parser.parse_args()
    
    return args


def load_data(snps_file_path, indels_file_path):
    """Loads data about SNPs and indels from VCF files into one DataFrame"""
    dtype = {'CHROM': 'string'} # defined to avoid warning about mixed dtype

    snps_df = pd.read_csv(snps_file_path, delimiter="\t", dtype = dtype)
    snps_df['Variant'] = 'SNPs'

    indels_df = pd.read_csv(indels_file_path, delimiter="\t", dtype = dtype)
    indels_df['Variant'] = 'Indels'

    return pd.concat([snps_df, indels_df], ignore_index=True)


def parse_filter_values(config_file_path):
    """Parse config file to extract filter values"""
    with open(config_file_path, 'r') as stream:
        filters_dict = yaml.safe_load(stream)['params']['gatk']['filtering']

    filter_values = {v:{} for v in VARIANTS}

    for variant in VARIANTS:
      for filter in filters_dict[variant.lower()].split('||'):
        var, _, val = filter.split()
        filter_values[variant][var] = float(val)

    return filter_values

def main():
    args = parse_arguments()
    
    # create DataFrame with concatenated data (SNPs, Indels) 
    df = load_data(args.snps_file, args.indels_file)

    # extract values for used filters 
    filter_values = parse_filter_values(args.config_file)

    # generate density plot for each filter
    if args.all:
      vars_to_plot = ['QD', 'QUAL', 'FS', 'MQ', 'MQRankSum', 'SOR', 'ReadPosRankSum']
    else:
      # chosing only variables with defined cut off values
      vars_to_plot = set([var_nm for var_nm in filter_values[variant] \
                          for variant in VARIANTS])
    n_cols = len(vars_to_plot)

    fig, axis = plt.subplots(round(n_cols/2), 2, figsize=(14,20))

    for i, var in enumerate(vars_to_plot):
      row, col = i//2, i%2
      sns.kdeplot(data=df, x=var, hue='Variant', fill=True, ax=axis[row,col], 
                  palette=COLORS['fill'])

      for v in VARIANTS:
          if var in filter_values[v]:
            axis[row,col].axvline(filter_values[v][var], linewidth=1.5, 
                      color=COLORS['vline'][v])

    if n_cols%2!=0: axis[round(n_cols/2)-1,1].set_axis_off()

    plt.tight_layout()
    plt.savefig(args.output, format=args.fmt.lower())
    print(f"Visualizations of filter values have been created successfully: {args.output}.")

if __name__ == '__main__':
    main()