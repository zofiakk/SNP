import allel
import argparse
import seaborn as sns
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib_venn import venn2
import plotly.express as px
import plotly.graph_objects as go
from plotly.subplots import make_subplots


def parse_arguments():
    """Read arguments from a command line."""
    desc = 'Script for generating visualisations'
    parser = argparse.ArgumentParser(description=desc)
    parser.add_argument("-c", '--control', default='control_variants.annotated.vcf',
                        help='VCF file with control variants.')
    parser.add_argument("-t", '--test', default='test_variants.annotated.vcf',
                        help='VCF file with test variants.')
    parser.add_argument("-o1", '--heatmaps', default='heatmaps.png',
                        help='Name of the output file with transition heatmaps.')
    parser.add_argument("-o2", '--venn', default='venn.png',
                        help='Name of the output file with Venn diagram.')
    parser.add_argument("-o3", '--var_loc', default='variant_locations.png',
                        help='Name of the output file with Venn diagram.')
    args = parser.parse_args()
    return args


def prepare_dataframe(vcf_file):
    raw_df = allel.vcf_to_dataframe(vcf_file, fields='*')
    raw_df['VAR_ID'] = raw_df.agg(lambda x: f"{x['CHROM']}_{x['POS']}", axis=1)

    colnames = ['Allele', 'Consequence', 'IMPACT', 'SYMBOL', 'Gene', 'Feature_type', 'Feature', 'BIOTYPE',
                'EXON', 'INTRON', 'HGVSc', 'HGVSp', 'cDNA_position', 'CDS_position', 'Protein_position',
                'Amino_acids', 'Codons', 'Existing_variation', 'DISTANCE', 'STRAND', 'FLAGS', 'VARIANT_CLASS',
                'SYMBOL_SOURCE', 'HGNC_ID', 'CANONICAL', 'MANE_SELECT', 'MANE_PLUS_CLINICAL', 'TSL', 'APPRIS',
                'CCDS', 'ENSP', 'SWISSPROT', 'TREMBL', 'UNIPARC', 'UNIPROT_ISOFORM', 'GENE_PHENO', 'SIFT',
                'DOMAINS', 'miRNA', 'HGVS_OFFSET', 'AF', 'AFR_AF', 'AMR_AF', 'EAS_AF', 'EUR_AF', 'SAS_AF',
                'AA_AF', 'EA_AF', 'gnomAD_AF', 'gnomAD_AFR_AF', 'gnomAD_AMR_AF', 'gnomAD_ASJ_AF', 'gnomAD_EAS_AF',
                'gnomAD_FIN_AF', 'gnomAD_NFE_AF', 'gnomAD_OTH_AF', 'gnomAD_SAS_AF', 'MAX_AF', 'MAX_AF_POPS',
                'CLIN_SIG', 'SOMATIC', 'PHENO', 'PUBMED', 'MOTIF_NAME', 'MOTIF_POS', 'HIGH_INF_POS',
                'MOTIF_SCORE_CHANGE', 'TRANSCRIPTION_FACTORS', 'LoFtool']

    CSQ_df = raw_df['CSQ'].str.split("|", expand=True)
    CSQ_df.columns = colnames
    out_df = pd.concat([raw_df, CSQ_df[['Consequence', 'Gene', 'Existing_variation']]], axis=1, join="inner")

    return out_df


def wide_to_long_df(data):
    df = data[['VAR_ID', 'CHROM', 'POS', 'REF', 'ALT_1', 'ALT_2', 'ALT_3', 'is_snp']].reset_index()
    df['IDX'] = df.index

    # transform wide table to long with non-null REF->ALT variables
    df_long = pd.wide_to_long(df, stubnames='ALT', sep="_", i=['IDX', 'VAR_ID', 'REF', 'is_snp'],
                              j='SAMPLE')
    df_long.dropna(subset='ALT', inplace=True)
    df_long.reset_index(inplace=True)
    df_long.drop(['CHROM', 'POS', 'index'], axis=1, inplace=True)

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


def prepare_pie_data(data, snps_only=False):
    if snps_only:
        data_tmp = data[data['is_snp'] == 1]
    else:
        data_tmp = data

    loc = data_tmp['Consequence'].str.split('&', expand=True)
    loc_vars = [f'LOC_{i + 1}' for i in range(loc.shape[1])]
    loc.columns = loc_vars
    df_tmp = pd.melt(loc, value_vars=loc_vars, value_name='LOC')
    df_pct = df_tmp['LOC'].value_counts().rename_axis('Consequence').reset_index(name='Counts')
    df_pct['Consequence'] = df_pct['Consequence'].str.replace("_", " ")

    return df_pct


def generate_pie_plots(df_dict, out, cutoff=1, snps_only=False):
    keys = df_dict.keys()
    fig = make_subplots(1, 2, specs=[[{'type': 'domain'}, {'type': 'domain'}]],
                        subplot_titles=[f"{k.capitalize()} sample" for k in keys])

    for i, k in enumerate(df_dict):
        df_pie = prepare_pie_data(df_dict[k], snps_only=snps_only)
        cutoff_num = round(0.01 * cutoff * (df_pie['Counts'].sum()))
        df_tmp = df_pie[df_pie['Counts'] >= cutoff_num]
        labels = df_tmp['Consequence'].values
        values = df_tmp['Counts'].values

        n_col = len(labels)
        colors = px.colors.sample_colorscale("turbo", [n / (n_col - 1) for n in range(n_col)])

        fig.add_trace(go.Pie(labels=labels, values=values, scalegroup='one',
                             insidetextorientation='horizontal',
                             marker_colors=colors),
                      1, i + 1
                      )

    fig.update_layout(title={
        'text': 'Locations of identified variants',
        'y': 0.9,
        'x': 0.4,
        'xanchor': 'center',
        'yanchor': 'top'
    },
        width=1200,
        height=500
    )
    fig.write_image(out)


def generate_heatmaps(input_dict, out):
    sns.set(font_scale=0.7)
    fig, axes = plt.subplots(1, 2)

    for i, (sample, data) in enumerate(input_dict.items()):
        count_df = extract_transitions(data)
        sns.heatmap(count_df, annot=True, fmt=".1%", ax=axes[i], cmap="YlGnBu", robust=True,
                    cbar_kws={'format': '%.0f%%', 'ticks': [0, 25]}, vmin=0.0, vmax=0.25, cbar=False, square=True)
        axes[i].set_title(f"{sample.title()} data", fontsize=12)
        axes[i].set_ylabel("Reference", fontsize=10)
        axes[i].set_xlabel("Alternative", fontsize=10)

    fig.suptitle("Variant frequency heatmaps", fontsize=16)
    plt.tight_layout()
    plt.savefig(out, format='png')


def generate_venn_diagram(input_dict, out, snps_only=False):
    if snps_only:
        tmp_dict = {k: d.loc[d['is_snp']] for k, d in input_dict.items()}
    else:
        tmp_dict = input_dict

    plt.figure()
    v = venn2([set(tmp_dict['control']['VAR_ID'].to_list()),
               set(tmp_dict['test']['VAR_ID'].to_list())],
              set_labels=('Control', 'Test'),
              set_colors=('mediumturquoise', 'lightcoral'),
              alpha=0.7
              )
    plt.title("Venn diagram of identified variants", fontsize=13)
    plt.savefig(out, format='png')


def main():
    args = parse_arguments()

    # prepare data structures
    dfs = {'control': args.control, 'test': args.test}
    long_dfs = dict.fromkeys(dfs)

    for group, file in dfs.items():
        df = prepare_dataframe(file)
        dfs[group] = df  # full data
        long_dfs[group] = wide_to_long_df(df)  # wide to long by ALT_*

    # generate plots
    generate_heatmaps(long_dfs, out=args.heatmaps)
    generate_venn_diagram(long_dfs, out=args.venn)
    generate_pie_plots(dfs, out=args.var_loc)


if __name__ == '__main__':
    main()
