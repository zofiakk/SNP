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
    parser.add_argument("-sc", '--snps_ctrl', required=True,
                        help='Input file with SNPs in VCF format.')
    parser.add_argument("-st", '--snps_test', required=True,
                        help='Input file with SNPs in VCF format.')
    parser.add_argument("-ic", '--indels_ctrl', required=True,
                        help='Input file with indels in VCF format.')
    parser.add_argument("-it", '--indels_test', required=True,
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


def load_data(snps_ctrl, snps_test, indels_ctrl, indels_test):
    """Loads data about SNPs and indels from VCF files into one DataFrame"""
    dtype = {'CHROM': 'string'}  # defined to avoid warning about mixed dtype

    snps_ctrl_df = pd.read_csv(snps_ctrl, delimiter="\t", dtype=dtype)
    snps_ctrl_df['Variant'] = 'SNPs'
    snps_ctrl_df['Group'] = 'Control'

    indels_ctrl_df = pd.read_csv(indels_ctrl, delimiter="\t", dtype=dtype)
    indels_ctrl_df['Variant'] = 'Indels'
    indels_ctrl_df['Group'] = 'Control'

    snps_test_df = pd.read_csv(snps_test, delimiter="\t", dtype=dtype)
    snps_test_df['Variant'] = 'SNPs'
    snps_test_df['Group'] = 'Test'

    indels_test_df = pd.read_csv(indels_test, delimiter="\t", dtype=dtype)
    indels_test_df['Variant'] = 'Indels'
    indels_test_df['Group'] = 'Test'

    df_test = pd.concat([snps_test_df, indels_test_df], ignore_index=True)
    df_control = pd.concat([snps_ctrl_df, indels_ctrl_df], ignore_index=True)

    return df_control, df_test


def parse_filter_values(config_file_path):
    """Parse config file to extract filter values"""
    variant_keys = {'SNPs': 'snvs', 'Indels': 'indels'}
    filter_values = {v: {} for v in VARIANTS}

    with open(config_file_path, 'r') as stream:
        filters_dict = yaml.safe_load(stream)['params']['gatk']['filtering']

    for variant in VARIANTS:
        for filter in filters_dict[variant_keys[variant]].split('||'):
            var, _, val = filter.split()
            filter_values[variant][var] = float(val)

    return filter_values


def main():
    args = parse_arguments()

    # create DataFrame with concatenated data (SNPs, Indels)
    df_ctl, df_tst = load_data(
        args.snps_ctrl, args.snps_test, args.indels_ctrl, args.indels_test)

    # extract values for used filters
    filter_values = parse_filter_values(args.config_file)

    # generate density plot for each filter
    if args.all:
        vars_to_plot = [
            'QD',
            'QUAL',
            'FS',
            'MQ',
            'MQRankSum',
            'SOR',
            'ReadPosRankSum']
    else:
        # chosing only variables with defined cut off values
        vars_to_plot = set([var_nm for var_nm in filter_values[variant]
                            for variant in VARIANTS])
    n_cols = len(vars_to_plot)

    fig, axis = plt.subplots(n_cols, 2, figsize=(8, 20))
    axis[0, 0].set_title("Control Group\n", fontweight="bold")
    axis[0, 1].set_title("Test Group\n", fontweight="bold")

    for i, var in enumerate(vars_to_plot):
        sns.kdeplot(data=df_ctl, x=var, hue='Variant', fill=True, ax=axis[i, 0],
                    palette=COLORS['fill'], bw_adjust=0.3)

        sns.kdeplot(data=df_tst, x=var, hue='Variant', fill=True, ax=axis[i, 1],
                    palette=COLORS['fill'], bw_adjust=0.3)

        for v in VARIANTS:
            if var in filter_values[v]:
                for group in range(2):
                    axis[i, group].axvline(filter_values[v][var], linewidth=1.5,
                                           color=COLORS['vline'][v])

    plt.tight_layout()
    plt.savefig(args.output, format=args.fmt.lower())

if __name__ == '__main__':
    main()