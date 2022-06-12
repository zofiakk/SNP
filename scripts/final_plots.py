import allel
import argparse
import seaborn as sns
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib_venn import venn2


def parse_arguments():
    """Read arguments from a command line."""
    desc = 'Script for generating visualisations'
    parser = argparse.ArgumentParser(description=desc)
    parser.add_argument("-c", '--control', default='control_variants.annotated.vcf',
                        help='VCF file with control variants.')
    parser.add_argument("-t", '--test', default='test_variants.annotated.vcf',
                        help='VCF file with test variants.')
    parser.add_argument("-o1", '--heatmaps', default='heatmap.png',
                        help='Name of the output file with transition heatmaps.')
    parser.add_argument("-o2", '--venn', default='venn.png',
                        help='Name of the output file with Venn diagram.')
    args = parser.parse_args()
    return args


def wide_to_long_vcf(data):
    df = data.reset_index()[['CHROM','POS','REF', 'ALT_1', 'ALT_2', 'ALT_3']]
    df['IDX'] = df.index
    df['VAR_ID'] = df.agg(lambda x: f"{x['CHROM']}_{x['POS']}", axis=1)

    # transform wide table to long with non-null REF->ALT variables
    df_long = pd.wide_to_long(df, stubnames='ALT', sep="_", i=['IDX','VAR_ID', 'REF'], j='SAMPLE').reset_index()
    df_long.dropna(subset='ALT', inplace=True)
    df_long.loc['TYPE'] = 'indel'

    snp_cond = (df_long.REF.str.len() == 1) & (df_long.ALT.str.len() == 1)
    df_long.loc[snp_cond, 'TYPE'] = 'snp'
    df_long.drop(['CHROM','POS','IDX'], axis=1, inplace=True)

    return df_long


def extract_transitions(input_data):
    data = input_data.copy()

    # multiple nucleotides -> one
    data.loc[(data.REF.str.len() == 1) & (data.ALT.str.len() > 1), 'REF'] = '-'

    # mark longer sequences of nucleotides
    data.loc[data.REF.str.len() > 1, 'REF'] = '*'
    data.loc[data.ALT.str.len() > 1, 'ALT'] = '*'

    counts = data.groupby(['REF', 'ALT']).size().reset_index(name="COUNT")
    counts['COUNT'] = counts['COUNT'] / data.shape[0]  # get %
    count_matrix = counts.pivot(index='REF', columns='ALT', values='COUNT')

    return count_matrix


def generate_heatmaps(input_dict, out):
    sns.set(font_scale=0.7)
    fig, axes = plt.subplots(1, 2)

    for i, (title, data) in enumerate(input_dict.items()):
        count_df = extract_transitions(data)
        sns.heatmap(count_df, annot=True, fmt=".1%", ax=axes[i], cmap="YlGnBu", robust=True,
                    cbar_kws={'format': '%.0f%%', 'ticks': [0, 25]}, vmin=0.0, vmax=0.25, cbar=False, square=True)
        axes[i].set_title(title, fontsize=12)
        axes[i].set_ylabel("Reference", fontsize=10)
        axes[i].set_xlabel("Alternative", fontsize=10)

    fig.suptitle("Transition frequency", fontsize=16)
    plt.tight_layout()
    plt.savefig(out, format='png')

    
def generate_venn_diagram(input_dict, out):
    snps_dict = {k: d.loc[d['TYPE']=='snp'] for k, d in input_dict.items()}
    plt.figure()
    v = venn2([set(snps_dict['Control Group']['VAR_ID'].to_list()),
               set(snps_dict['Test Group']['VAR_ID'].to_list())],
              set_labels=('Control Group', 'Test Group'),
              set_colors=('mediumturquoise', 'lightcoral'),
              alpha=0.7
          )
    plt.savefig(out, format='png')

    
def load_vcf(vcf_file):
    raw_df = allel.vcf_to_dataframe(vcf_file)
    return wide_to_long_vcf(raw_df)


def main():
    args = parse_arguments()

    df_dict = {
        'Control Group': load_vcf(args.control),
        'Test Group': load_vcf(args.test)
    }

    generate_heatmaps(df_dict, out=args.heatmaps)
    generate_venn_diagram(df_dict, out=args.venn)


if __name__ == '__main__':
    main()