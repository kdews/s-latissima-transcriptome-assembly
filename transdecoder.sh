#!/bin/bash
#SBATCH --mem=5gb
#SBATCH --time=01:00:00

assembly=`ls *fa*`

TransDecoder.LongOrfs -t ${assembly}
TransDecoder.Predict --no_refine_starts -t ${assembly}

