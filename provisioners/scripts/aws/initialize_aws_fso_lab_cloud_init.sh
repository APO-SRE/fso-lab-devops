#!/bin/sh -eux
# appdynamics aws fso lab cloud-init script to initialize aws ec2 instance launched from ami.

# set default values for input environment variables if not set. -----------------------------------
# [OPTIONAL] aws user and host name config parameters [w/ defaults].
user_name="${user_name:-ec2-user}"
aws_ec2_hostname="${aws_ec2_hostname:-fso-lab-vm}"
aws_ec2_domain="${aws_ec2_domain:-localdomain}"
aws_region_name="${aws_region_name:-us-west-1}"
use_aws_ec2_num_suffix="${use_aws_ec2_num_suffix:-true}"
aws_eks_cluster_name="${aws_eks_cluster_name:-fso-lab-xxxxx-eks-cluster}"
iks_cluster_name="${iks_cluster_name:-AppD-FSO-Lab-01-IKS}"
iks_kubeconfig_file="${iks_kubeconfig_file:-AppD-FSO-Lab-01-IKS-kubeconfig.yml}"
lab_number="${lab_number:-1}"

# configure public keys for specified user. --------------------------------------------------------
user_home=$(eval echo "~${user_name}")
user_authorized_keys_file="${user_home}/.ssh/authorized_keys"
user_key_name="FSO-Lab-DevOps"
user_public_key="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC/wWW+/qc7amCKl/xVrNdVtbSUtWniw5CVHChWqIJU0vef8nQESLU6RPot54r6gzjfNegQFNqaJL+F9JeDVRZ1jYl78+yvmJMCX2ylNIJlfe/owHcFjzWdfDafeusktwifoMSEvc+KouGQinDrrWE5LC8XXkxWjQIwR0Dzv1W/BoiwpPf1F78w2HRRmTkJ6IwSC3Bry0IfmPKTi9OxBAuzJ34gzxIjeb/U8jEABLs0MIkZ8qpVh1s7lv1c7rZ7y3is+fdEqhPeTr03zjIiKerer/5yjjYKE3nsGqEGSQjwrVDw5aEQmtTRBY6G6usP9PLQaRwncJulXngr1k7E7qcz FSO-Lab-DevOps"

# 'grep' to see if the user's public key is already present, if not, append to the file.
grep -qF "${user_key_name}" ${user_authorized_keys_file} || echo "${user_public_key}}" >> ${user_authorized_keys_file}
chmod 600 ${user_authorized_keys_file}

# public keys from appdynamics channel sales team accounts for ed barberis.
aws_cloud9_key_name_01="ed.barberis+395719258032@cloud9.amazon.com"
aws_cloud9_public_key_01="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDXAgvFPH5MJa0P2EUKpv4ydb8INyyF/oTR8+gyOgutCd7CLUO8Bv1C1gR6cl1zbFwBriiMZ7g1zWJCjFOWrbfOXEDOR1FZ/16Pn4obUVVRkkJngqQlCKef5GVZvXTdTRd7tr6o5aBhooZKkbLzggAy/Ex1o+6wWT36oziCJQGk65mrZbvj2ABpeJsxh/FZDesCHXSYnnAeHsUZg9sD84MpC6hV7PROW2TOktWueUDxZ9XtsUFobdUF1nWT6TyTal2/VA6rvCZ+1L7/3caYJ+yHb5bqT//hOXIiHRt+ICo+nvovt99ubFtlgJ5sOf+TZgLl3TgB+oPS9xbf6l1hw7BJYyvD0fUiqoibM6nR7QtUCC7g+zVHYZhKsOeJYUpRFYiWTOTPkxMZ3zNbdhg27Iys3czMoWeF3LxWsIrKB8jAfJC7RE5cvnEF259bfwW4LpzJtL5DflhnRI/hBvgiAApTyJYr+qnfXfWoswTtsk4TeeZzccoYQhshbTXXYPq3YxZfPSu3GQrT9VnF6AjC6cTGH30n1SmqYj43V6RNzw78xbcmUuaEoxIfWgT4LXMEjQ5QMScFKpDctfqocIxQ1e6PYs9roUNIpKxqw+sHPblRVWMKAExBywgCPmGZXBkgo3EPjhBe0Rgz2bPIABuZ7ML9CH1dvyCt+OhzVDRN9P2Nww== ed.barberis+395719258032@cloud9.amazon.com"

aws_cloud9_key_name_02="admin+395719258032@cloud9.amazon.com"
aws_cloud9_public_key_02="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQD24LU5iz7KYgpHjDIjanixi/l6e5g9s7ZHG9yGoIKhrx8vcVuTV2s0Awk+kZPCnQjZDC037qPHItryzc++omNKhBVGNZa3Nx+QvBwmF1rGZedQ19JYstEeOXZpCVDTupnGeHqwu/+EqDiE3+tyNfXT0jWgPI5+5eRnZ2c30thhLugtVNv7d1/gU1FleGgaIKTbfkWTWVxV3U6PxuXJPCTN+l+S3EmEhZlDoY/qJ3py0KwhgAT2n7eGumUnvHguq01cprLVeUaHvncPOv4DNpGwjLgN7rdj/ZC9mtHBtSQeq/asEP6upfexTTj2KSXFctWSFNPAbDcVDl6fSy1HhLBMn3dBZBXJDvwrhu0tHuz1SWC8dV7JDjHwdi3zwmeCi9f6VvwsGMCbCWqVb6Kr9+3MGoz9lFBvN+9JEjkbxAx0Bc2aHSRbE2ZjpikiJ49QNnWX8Z4dNhyBT2zryIljKu5nzmtgPnkoarnYKQqt2I4Do6EOZ7BOjZFFJmcHET3zauSlqWeBVV3amvjsR1BHvU0e1FhKxvEBY3QA2zc4+UdtmwIR1kgc0YvgUOHU5Mt1h3DuXUFVUFSpTvzOtaS8TG7gdsDPblOipyW2RpGzYQGPVYs6mH7oCsQNrXSPJPhyAsTo0BHTlDugSL88i/It/I7Ljs/kpRWaIJAKJCIwjk9wQw== admin+395719258032@cloud9.amazon.com"

aws_cloud9_key_name_03="ed.barberis+975944588697@cloud9.amazon.com"
aws_cloud9_public_key_03="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDeV+SMmfQyUXpr9SfKDMZg0QWTg5X/ymBv0Yu7dDkDCzLRJRoQpJh2Dk3/Aumegz1sxyWQnha5Lfpj9sE2tYq6k9qJnCF1efsEG8Lgc3wyBojNfiW6v8N5ekn9ZqzodC+rNhteTitI5BePvnTZmWJBNmz5aUUlQKfQqtSgW/xJy7mWsGzHgLkUhcaFjfugOW1zDkSEJdqclAFhVhnYbxuM4ecF1LiS5iWy2I/BenysUyN9ChFVhMtYSNORDo/0E4ftti+iFPbbupzGyE2nwCIc4SammIOEqm7DLwmUBfxI47d5KP+DNv0ycYWNQam3Sq8EJmLty71KnTXq+hitV6e+YHEzk8eoIdGALTcvKgyhcRXzPIIeKqSfPeN6zd3jHQsKt9/8FFAOfhNHdBGMNDulHRwpPG3thtcH/RWcr599sIAeTEy1DG5acFW0rtLJYM4hXCvuy0eN2JrUEAzBxWu9+iAXKKnWNFZhlafZEfUyMFyON6cbrMwt0TqFSnB1FQcDu5X/H+mGlySTz0bmxedxv7mwmQ3t+xc5VF0RMmzp3mvs3pdsD4g7qm7/hyzYtgoso1OjM2PekqLIY8Hn/0kR0yRlXZm3Ko5ODY0KKFHWb+xTwmDYjIjppsgE9IrrhSRORLcAhLPZzYCOK4Eq2/wYh9kDGU7GV2MxbUoX9a4jRw== ed.barberis+975944588697@cloud9.amazon.com"

aws_cloud9_key_name_04="AWSReservedSSO_appd-aws-975944588697-dev_35531c6d12fd4c96+975944588697@cloud9.amazon.com"
aws_cloud9_public_key_04="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCoy2S+6UkE3xLPOehCR7eXcqlG0djS/PsIRv+YYO+0MfKBfvVG4hZOhiVPfcyv0XcCSmk4H6NWGHEdfo8PrPs40nMwdZnBvarekK3580X7melF9zF8c/nA1PL4B8WbbFE96Ny30lm98Ji4ZbyCh0xgr1J68jcZuZIyoeqigKYH5lcpJoUWN6vG7jFCI/JEB975U9kGHDcIkSvLib2C26oszfkKw67UXCOdWeT8mEYm8hKrVPTXssjpM+8VxkMBQBZVZ+UOcwx8hCFx8wYeOV67CnJtegUySTsxVoUo1sK7Dw3QIEI9HqcTnqssF+C5neEHCmeYn5H8hmpFxnFipJBMtuCneHstJnd0qSuLS6eZe8rHRdQVQ+1sOnC2TplF+9s/7Tn9SlTB6K5jq1FLsegOyoxgDlOvX36f0q86MtqosW33Uxp47f5KtoXwaeV18N/fqeHV3o9sgq0DlCY4goxRUMN/4y2gLjzQREaZtsLZf7c5IZP7fuXWxicr2YBSsEmUsn9U7T/dCWSKZ1ijuu9hFVcApb6P8Afv15pHW0sL4xdvQNZaStP15CVNHHjfhJmNJAOrk8SPDhk4f2SZ++qLM9HZ2/CnduwlwlKLnV6YFXWgpycztWr34Kor885v4TqojWXuoqZv3D0JNaZ3+Y4UlmZlw4njlEjarROLC/Xk5w== AWSReservedSSO_appd-aws-975944588697-dev_35531c6d12fd4c96+975944588697@cloud9.amazon.com"

# public keys from appdynamics channel sales team accounts for james schneider.
aws_cloud9_key_name_05="james.schneider+395719258032@cloud9.amazon.com"
aws_cloud9_public_key_05="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCnA5IwRyA5ZIVYzlSe/aNfGAqMMWAC5HBkwvC+Ci6H2fNfaZ17ftb0KTOYMOZ4SYEYz4/xRJK5AbJn9/asxd60DWYqE7HYonPW/4XX3caUteslxRpSAP9pAai2qZDaJUpy+Stey/31zbYMyCb0xq3vSfP3nNiNCS/IGvCRFZyNQuIZ8SlGyhLAYRpPWvn3yw6pAdBJXxiDMEF0t6H1G8jZDtGhWka9tRcHU596luZQb4XDNwkrw3FmZTOJxzetcJgiRxiG5oRfs1G4xgogFEXMQhmfrEg7BlxqzZhRCDsmUDJFYbL3C5jvSPztcOXn/XwEJ14x4D7rsSoAdPBhgzF+iPtjEUpBlqEa+J+Fpdr2m6JDdoRMgEP/2jBpjvqfwJNSRooXPgw/Gfkja+9/S4IWfNI5n8MC1iZwa7rzGjZn2lwtC32oq3WTkf2IfSm5WAG9bsG+15U4RM6oKAhPzalByOJsT9H+S37LK/62PT9X/xEO/pF/2JKY1qpVPvDvC6fyU9Es6RgFYrRPuQ8fEu9vaK++aK2tc/X9jhzVuxxBJqV1tOlKVjjSKIE8DlRR3WFYbJOTdeScCCtfrC0Kx6D3nn3T4TL+aHkpM/vfBqGk5dOZRVCUn8YQx1Ilyqqm0+OiHeaoKSwXSUVh/zZw6Ls501pbxShlJiKhsgPNu65Cnw== james.schneider+395719258032@cloud9.amazon.com"

aws_cloud9_key_name_06="admin+395719258032@cloud9.amazon.com"
aws_cloud9_public_key_06="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC6hYtIrTPF00s0tXWwssI32TdDUzrVYWiHJDoKxstXlkVflsb7BVFSNaQdb3Z8hjnaSI2pP9+6zX9pGuXCqchEWw+QD96jnRzas87sdx5+DmSZPok+t3d60TJt/4YSSY5X9JlEkfDRlm3cKImPsoTKAptW/VON7wiWpwuNBHu7tb7rPZ2ndB4dKi5WPAiNEDh7xYpdgFYhR508N7gx4NiDJ1ziGdEtDeCRdEpCeed/xZC+vew+tSglI01j7+d+U3MzR7SFChCEAoHIPGUvca/sKlkyMnKzekZU3u2j7G9Mrb2dNWsEMf/RdWqquQmn0HAlmU1K+fxNwGuP+PzYM7Q0GZfv5OaNL932bfxcO6qddw2dkJOvEFv0aC3OuOwPwMvojf5J4S9Aki5Qc0qDeCTiKsqKMmYiPsQ5dkcsU50rjUQbLWqdKO1KMT2q8Mnr8/rZfDPbfvywgio6fyBL3O3goTUrgqx15t3vsJO4TCgaCZkzcxk/FANbciz35bq5I1V2fngth9a0iwSNpK2TpiIKlKmCAKEZXBcjxHLGCHF6kE8cNIDnMkpKUK1q74XjAysXL8VoT7qfoWGQiRVPbU/QEbfZCG3sc0HikYDVMM2W8U/eaiqrKMTZn7otTYdH4Lo2fTtkW8vh9N3CAT0nh6+cM0rB+hSSNjl2jJ9n0UumeQ== admin+395719258032@cloud9.amazon.com"

aws_cloud9_key_name_07="james.schneider+975944588697@cloud9.amazon.com"
aws_cloud9_public_key_07="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCsaMxabVbUscPI8I/f0yecMQWdCKlmrIeLN4bDTuAQpEZS3BHXx+hr1I/i6xi4K7gxLYyQN/wQwEX8J4YJhgM1xTIYlkKoI9BqRRLqjjm1Z4bPnVUR8GtTvF3A0Z0Aecua3zCig8Vw6nNPM12HjV9KptCSqX0fRyKjUVIMax7mmj1kvGgkeT6SeG/l5JJlnVXSWhitiWthFLyZ7wM5iodo1q4yiyqUNh/GgV1Xf4/puEhXwdSK30NLD2aoqZKh/bejntUMdw66VAlon1PtvSDpbUQqlelyMnwnoOgYE23hlVmBhg3hJX5guXhBxjANuRTezY8U7/mp2BFgnlpbi45vGqWA0tAyI8obFNXPB79gYOYVJ1vGb5O2SXMp0NelhhEQ3LUZVU1SyvjGgD+HLv33J+sZrvJxoNP2aVnwgh7hSWyXq+Taqa4Z3afVBaEuI7S6/uIAGOYlq/gvSBLlqthoMV6ZA83cMXoMfHqTOarmUrwJzhJumDUuITNmuJclyHs+YRGaoBoisFtKl7uFoGHNpYQy2iQshcK42xkltvMUxgpDubK+NADAJB0k2XEoQeuQFQVbNdVlKcr/PCMM4tlb1qNoqwX3ERtEikygHVfM+3ngF+MMUcLF9rGdPfiDwaeKSbKEHbYjXb2bAhF5Rz9cp0aEpfOVbzYFjKp2SF5WVw== james.schneider+975944588697@cloud9.amazon.com"

aws_cloud9_key_name_08="AWSReservedSSO_appd-aws-975944588697-dev_35531c6d12fd4c96+975944588697@cloud9.amazon.com"
aws_cloud9_public_key_08="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCz2DnYKFZ0oj197z6hLvyBTNvA5UBYa+kbTOuPV0brphZxCspxQ4PLTdWyPIP+qO6aWvvXf3OEKJBWzKj9b4MkbayEWvrljVVOT/ndE+4NdbHjsEWpSAtfxx7h8ADD99iUSr9eHE6+hCLsiIM/TyIXtUK/6ToYX4XOK6ez32BcpoZcxJfR2tT0WwIvVmnnF7FngvPXbBXsvkntwa5RG8KJdHC2tvexHIDm8AShuOLAplSyBL8tzrJHOheBykVOlaowLQoNGOeAYLnsMEzOvbQ5KymKxlPcLRulsFuDvs8yVtCqctTzdWZPLnZNr4uUtjH/2LlID9Hq9rAdEAdskWZapddTh3r7bX81v0Tf+Hkuy6+hKcyQNKzOaodSMBXusje9NKCEkqXFM2kDFSv3gdfNLt9X8dMxLFWluieAv0r2xHrk6dzjHuMMBiHQz05dzI3g71AtrOTUDGX3rj5/sEeHCpeAjZr/bqwq5kbmNPbukek3Jc/g+ybLzxpouwd36lepkLckH24vZ+ySYcMumzBrHTm3Y9FF+PXhIZMW+e2/n+Aj16n+UnQNXQl7FVadNrwHN0QOp51L19guGV9jUVj8R4cUTc6dNXy9s3Qk4cJbQloJ6LJAwqz9W7hE8zRogWELoLKnr/0agCguN38wkYy1SVXLI/ktksIUQ1OjokLdlQ== AWSReservedSSO_appd-aws-975944588697-dev_35531c6d12fd4c96+975944588697@cloud9.amazon.com"

# public keys from appdynamics channel sales team accounts for ramiro nagles.
aws_cloud9_key_name_09="ramiro.nagles+975944588697@cloud9.amazon.com"
aws_cloud9_public_key_09="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDvQW+ic6k00u5auvPMhE5xzmxL5dQlRHjK6kay5LRAP4tmrLRWpanOaAjvaxc+4Rhxg4fjJSaGWTB83phEYfbqeLM0FcQTjB2gywdWSl861NU3QA5oE1gA7z4OV1DD2exiqNX38gOe+y7+wJqf0yyOiaQv2ghrOgNq/38mZe5RuXCZJsqGO6221CcR6WtxAZPdYuSI9bz7f2oLaD2nMry7MZ8fJ/4xkAyjTt2lr4OIEc0Tf2o9NzS2JQBLbbmAZXDOsUvx1C2VITABi46o1keQa0ifLbCSeFKitlJV+jKV6vukiFdokcfmyZrU+Lsf7m5mjWAt0HDxj5xB0xLBpEDVhaCJZ/HoSFgpmu6b3VmZlKiSZooQPpizkZpwoI26i1YJ05m4kWjbW4tfblpnqxJyOu5g+nXCiPdILo8nc9vixtDL8XZ57z2cH0DzqTNFUhnv5N+21SOP27xDba7QzGILP/Ja90XTpok7n+e3w0LRZANJCljDNLsNdBT00/RXkgGkLOhIV6karHps8hCmVCEA5PZqPA4yw2xB/tTA81RTbXuRD0fwVTWfQx7vtJ5sCshsVgI7hDvvfByw9fVsgsxzVtKiSzSFD6tXH+7ZU1Mah2mrEHwf8NON/5PuHpHp4wv9cTCnBpKOU8O8/kWRROHFZ50jlCzFfRnQvj1S6t1M3Q== ramiro.nagles+975944588697@cloud9.amazon.com"

aws_cloud9_key_name_10="AWSReservedSSO_appd-aws-975944588697-dev_35531c6d12fd4c96+975944588697@cloud9.amazon.com"
aws_cloud9_public_key_10="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCqLJ+wcH94/6ZTcvWxVyWfyGDrVxUEKbtK4ciNgoLb0L8HSTxzVHt9WUxIRQofp6ZbiYNfySOTmqLPErWO3TXPePPSb5JgAkgaR8gYafRwZkS6Tf5PFiorltraQKNmzmnCC0uLgQ6mxg65m/MOISXtYXtcnc9uTHWUIYDRilgVuwMoZtHg6gCKQ7l9qlhb76heqzuGvI+Yq6fR+HoLYo2v3v9HB66MnLB3TtqsztTW4KNdqZeQFYACgbeXWyCk5vYNMInQQ9kPzFAaAAcJ7b20fiDcMBBIPi9jq7QYs/K/Wgsazym0Uuorbr1A5lenOY9mCAvq9lR0S3cEI6PvgUwwn6AJYje6n8l9+diaRAOv/LFea5s08hSAXYFacYyW4XHRMGzCMTTMZNETTxCmsdKGjn+UEq8IE33u/pHs+Sw5PY+uabZGNDLSjEYOi7rvW8CCrHAePx5wDJw6JBdmBemgGVjwVY60sqFvjH0BYJZKFhVXltrBDyjRUeKd9/mt1TVzcKD/BpNTse6OWOaXbvyNlpTOf7L/4P1sDoqwoJRH8ALfiFhbdEVu9CT8N0QEsgrNpFEWXXWF0dUq/lFIAfW0ZW+yON+AsGCKrS+A/0bTbcb1QPURK45RMTb6PO96hcuBKcf3eVpg0/RyHCTmg67HHeuVT3xdiMT1bBkeXlt50Q== AWSReservedSSO_appd-aws-975944588697-dev_35531c6d12fd4c96+975944588697@cloud9.amazon.com"

# public keys from appdynamics channel sales team accounts for wayne brown.
aws_cloud9_key_name_11="wayne.brown+975944588697@cloud9.amazon.com"
aws_cloud9_public_key_11="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC2SOn8ufZigQiiHz+d4ijkgA3g97/PAYi3QfMtW7XzT/t0sHcQ4a9wKVN69YZN4skIzh1FwklzwlhOelvWuJWQ8l3vSPsgObF0hLyYIo9+E9n7OCUveHZvSLZS8duCbHazSQRKKCkHvtg0Vwx8Zyn889bypvEB+UvoAUGOoJchc9+ntUZ+DsaduSD+Xm6YnE0oIQBe6TDyZzAWGfCanfUg7q0Rpri9MlOEed0TyAHFDtVG9qyK3co/wilZcrGDQWTphbQEpUOJ/IYnqlcnpnu/u5pqMAu/Cx958/JgUR1EZI3wwslTLmPINQTg7dJ45VIcqAhcoIabPk99RpeQhDKK2A0/Slyn0wtp4oTru0leYXJl3ZzR2oa7R4pEAeoI2kuv5z8FTIQVuxHSLmoi9zXuV6HVSW1ovKwNllASk4nRg4+9zpjE6QcH9CM0vLH28fRhqtguO0T5kA6HgvUJGuVv7MAG5jL/dXQOYLhXSUFsgviyKzr/Lf/Ww3PPdoClpS3f2W5NqT7ofvpIp7mgWf++B7+b1vJLMosY7ARUrBbA0jdZO9Z3vQ8Ly5IwqfGEYmrM08NhMFumDKgB33eJueoAELrhllmA6WLN04yAaNzC7twVIo9D0/sg1FjVMzYodRAS7aIYQSbRrvsZRCRqfgA+g1H65ME4WQuEWPAyX2znxw== wayne.brown+975944588697@cloud9.amazon.com"

aws_cloud9_key_name_12="AWSReservedSSO_appd-aws-975944588697-dev_35531c6d12fd4c96+975944588697@cloud9.amazon.com"
aws_cloud9_public_key_12="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC6O+ItfkBs4Jx8vKgnoE/Vz3gYOkhVXkXp/7afKol5PKWWVTr/vl+dtgBtChGQTb5+O3WbMGhimnraF0atWWbmZNnJwnRr3lapLU4jkfdF2TdhTkqrwzOGslcgdKR+Qr5U9AdFMtH6CPWBkN6/hg4JlagNdNHrfH5gKLxwU3OwsXVowVMlw6U20wsHmz3R5tduxBc3NoRqo9aT8EGP7FSbHNGADv30j8BcoLPsQxclh7pWrw3GE0UTHP/OKdG3LqAXZKT2GMNdw1DtOpu2tqtnUcfFSrGuXhSdJNZpEyQQmP5tzjBXWx6QFijYX13x3USift96tg6JElklV+qpYFs4/oGHO2xq5j3KW0afdJbiW+29i1dDTakEFacFl2S+2M9wyJwkHTuXmP5tCZ1bb/mDsUhNvNzboxBQFLsEFAlHCLIRbYSJa1fsKSdonRTl6MY3O+HCp0lEu/1go9JdOMH0iRJdH6Fw4mN3Z0krOvpp9+wIqYyG488y9NViYERJmr1zH1AOpcVsHsqi7J7nqGHM+87wOLYXYpGjNrhD5vQcnrpUOU9TFVeuFX+a62tSwilYEf7O4NVk0x1qvek/uK0kk/RUq0hceEMJdI3+PrlFp7a811yB7p1B0+B6NMb5JU9sUMxBcSq3pSYwnp+izEJgq7N8rIUkWBW0OmurkSkuMQ== AWSReservedSSO_appd-aws-975944588697-dev_35531c6d12fd4c96+975944588697@cloud9.amazon.com"

# public key from appdynamics channel sales team account for pranav kumar.
aws_cloud9_key_name_13="AWSReservedSSO_appd-aws-975944588697-dev_35531c6d12fd4c96+975944588697@cloud9.amazon.com"
aws_cloud9_public_key_13="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDBW4yKp5vTj97E7zUjTXbm3lfqHkddZsOyRLki5QILk7+oe75Ng+awQ8qbDP9bFCTC4lHw19qEE2Cc7UmGXODh8GJzM6akpYhFNzmvwwC85+FAuveU+ibQ54vLfo95hYuoeBo6Ah95+swmA5kGvSY+sn5noBdVC7VPp2tZqlgIZnd2I9lJ99rUkelfV3M2GzMRI6fUJzxe8azEml2ETDIG9o84ShGmR6tiQhPxyotpQXlCuDnu5GJVVmbgqyOQM8ixFOcqtR/nhQK+3AUQ56O9hoR0csg3sG4+E9WnYC0ub3TT1VnBwA8P0IROPdPVPGg6d2pTDNQ5KGxZ/qTtR/+c8qDSYBLO7v0iB9Hxm9mzVuem13p7Gr+oa8ZV/zKHsELumHboVmYNsZ/WryUZ+2kA+f0Xz/yh+hc+guPixDLuDnS8AFgnPwXtccFjSE/KoaWGt9WYDAiEkYzxtgqe3BW3TulSYMbINYyNdVKmzS6mxn+iLSPwUHBLZuUUNMPOcvDP0AvkDcCFE1A24Yi0fJk8D7Aqb19wk49tPuTj3kJUmEuqXTMeNsmDqAK4zvaFCKnJElQTN2aOdN7wrIK4R5FmMn5XfauZQ4Vd5So0+IVflos962+9FzWxTWCYCfBGxN4hJ/LJ24KNPdh1eoIpHmCvY0jvFPexFVGwYtQjnlnxgw== AWSReservedSSO_appd-aws-975944588697-dev_35531c6d12fd4c96+975944588697@cloud9.amazon.com"

# public key from cisco sre account for the admin user (jeff teeter).
aws_cloud9_key_name_14="admin+496972728175@cloud9.amazon.com"
aws_cloud9_public_key_14="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDmqdLr5IM9GK15/RXrWyuoh0eVG50BIjIJwzgrjFIujQIMeuMS83h6jQV5Lqd3H3xMlUiRYErTAmnjAqtbA2C5klabPC4UiJjP2W9HQYmUh5Dp2mWW09RIsa0BfRF7oTgCjOxIai2r0cVk9YSFaIylz3KwFmDR7r1Jt6pAdyZzTvHrxDnUZX5XLFOx/h1If8vboEeenTk/B6NSX9s8RfnaFk31G9Bjosa733fgTUK7epYt7ArNnQyUhFRwBs+mDbxp95nlNrT5ASfJQzpAJdjRUOh3YEY8S3vbEEp5T9qMxehfqnrIfLN1NJSgUhAXovBTJLMv4cntHAjilbNKnr0yW1l4tKHKYOowuBHJ5drDcr1c8VkHtKhuLeqUpKdyK2A597Zr5f5fEoDHCZw16gzDuvLM9LhsDoh/U9OfSFuTBbnq5dPSpC1EYFmTU0Ws6OAlMFCYSzbFBl1dG30cbu+HI5Tvz1mUinajiRK9Txld24HSi7IAgQMv2fykeZFL5eWNW2C1wnHuSHYh8qVbU1StCRGcM4yQi8fOb1N9ZwHR/OpYixp2y3mjYSN8m1Z64gvGUv/ID1i+/mt1Fc0ip30YxegZW1knZNJOMta3KHm/0ef5qMQ1wfn0uJS1GcUE1ZPxAoMARuycwJm/iyMjDYWFr3Cf2NSa7fQ8uqch3wugbw== admin+496972728175@cloud9.amazon.com"

# public key from cisco sre account for the admin user (Stephen Bader).
aws_cloud9_key_name_15="admin+496972728175@cloud9.amazon.com"
aws_cloud9_public_key_15="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDAcNePZKTj6kFaA71UCiCK4GIW/ElfbOQn91DCvW/HO65PS/AGFMpmA9Hm37wLZtPFucBBi0IJr9uhYi1GOeCkjXNnl7KhqzEXhfeZoF0rZVSlXWNHzAazMOK1VPKC1BJdIIHInr1H9yzUC2QPj6W6WDyLdCnZFkdWqevz6+ta9T6xSSl7jfT/dcg7tCm+0KHOOFRwicQ1oTkvs4jqrvJ2RowN3A9ERrtot8AZnate5i1Co8EWa+KaP/TUWRc7sjal8utY68M1FPb6GfdhUcnTkN84ultuj1UpDCt1Q60MVrQEOw5UbR0V2ZjUhOrvPZTJRxp18gvMT0siBlPkTFbPNxRCZGw35jgvM1BD58ADy2QSTtIxk7QRGVOL8Pfc8ewWHpPLJsJApC/88sBVSz+jhXbvEADEb49DnsG3mw3RfKh8cxZZCjCkz/M7FLtkpDzaNmJJM3NLzz2daVO/HqNF4C3wzqBJ07D3klOYIAP5DY6rCuhfzl0aqsLxpl0Zmcc4XQJL7nEMz81u8infIB2bC54Hc07gHUmKA414Z7WCKq7l1jiffQ0H+zaX0lbPlYppQY6NYPuN4tZ8Fb7If3JT188CRsycqrY84RAP0t9GBftY6cBtP+KWK2tO5tTNVCENnTD2vyfmmk020+u2g/ohD1n+YSYQUdg+3gdLpRclWw== admin+496972728175@cloud9.amazon.com"

# public key from cisco sre account for the admin user (John Meersma).
aws_cloud9_key_name_16="admin+496972728175@cloud9.amazon.com"
aws_cloud9_public_key_16="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDBpPsA19eAxyYbcJ4vLGcPYHGd0HIlIQ3h7LTYYl33dSWmIG+kpjkDeNDpTHtyqAyekKdjdAnHf85dMUps1BNVfoUusXnnYw1h6V3XlUsFLw0/GzJsS1aAT6a1TnaCQOytZQcnXy4st04pYQiDkvGqTmTL8xO7Q8RjpMTZnXvJyF5EtUfSEyFA6vB/zhFC68XzH2ofG1MrDeoIzurW3HaQr8bndOt20VBzS3Xdde4p1YBRtaCDErIBV/tNSHQZltVUr1Y1LAPUO/rp4vqZ9mov9OQuXTDWwOi6Bu0oP3sLJU6DsMsyFfNoszOpSyxZPz1QRtyZK2mexKRjr7hJT2pEzspkjL2iEKF5WtEpRmtPm3i0yB5XtV0s8YjRGmykqdGINBrsN29p7yCm1b2HzlNTieycnYB3du8zBDqgohE6drQOgFHN/MnHOgPNoHgEy3z9uIPHAM+V/RgAIybInpF1kg8+f0pHealC23VDNFTXLhYe2l8WGDn5qBRGMRjWRQUMqqmYUSMteMNYUaO9ZM+0n+VMaDUtxh8LGRrd5iX2dDGJUga7ESI6Rf66AChfZ1KJ90lAM37rrtwv4u12GXawouKvYADt7xmXBQd0Cjym2lVr4OIaO6OUwxl+XA1R79W/1ZadlPWAXf/5f1eryS40o1aipgcD9E+906z8cVXUww== admin+496972728175@cloud9.amazon.com"

# 'grep' to see if the aws cloud9 public key is already present, if not, append to the file.
grep -qF "${aws_cloud9_key_name_01}" ${user_authorized_keys_file} || echo "${aws_cloud9_public_key_01}}" >> ${user_authorized_keys_file}
grep -qF "${aws_cloud9_key_name_02}" ${user_authorized_keys_file} || echo "${aws_cloud9_public_key_02}}" >> ${user_authorized_keys_file}
grep -qF "${aws_cloud9_key_name_03}" ${user_authorized_keys_file} || echo "${aws_cloud9_public_key_03}}" >> ${user_authorized_keys_file}
grep -qF "${aws_cloud9_key_name_04}" ${user_authorized_keys_file} || echo "${aws_cloud9_public_key_04}}" >> ${user_authorized_keys_file}
grep -qF "${aws_cloud9_key_name_05}" ${user_authorized_keys_file} || echo "${aws_cloud9_public_key_05}}" >> ${user_authorized_keys_file}
grep -qF "${aws_cloud9_key_name_06}" ${user_authorized_keys_file} || echo "${aws_cloud9_public_key_06}}" >> ${user_authorized_keys_file}
grep -qF "${aws_cloud9_key_name_07}" ${user_authorized_keys_file} || echo "${aws_cloud9_public_key_07}}" >> ${user_authorized_keys_file}
grep -qF "${aws_cloud9_key_name_08}" ${user_authorized_keys_file} || echo "${aws_cloud9_public_key_08}}" >> ${user_authorized_keys_file}
grep -qF "${aws_cloud9_key_name_09}" ${user_authorized_keys_file} || echo "${aws_cloud9_public_key_09}}" >> ${user_authorized_keys_file}
grep -qF "${aws_cloud9_key_name_10}" ${user_authorized_keys_file} || echo "${aws_cloud9_public_key_10}}" >> ${user_authorized_keys_file}
grep -qF "${aws_cloud9_key_name_11}" ${user_authorized_keys_file} || echo "${aws_cloud9_public_key_11}}" >> ${user_authorized_keys_file}
grep -qF "${aws_cloud9_key_name_12}" ${user_authorized_keys_file} || echo "${aws_cloud9_public_key_12}}" >> ${user_authorized_keys_file}
grep -qF "${aws_cloud9_key_name_13}" ${user_authorized_keys_file} || echo "${aws_cloud9_public_key_13}}" >> ${user_authorized_keys_file}
grep -qF "${aws_cloud9_key_name_14}" ${user_authorized_keys_file} || echo "${aws_cloud9_public_key_14}}" >> ${user_authorized_keys_file}
grep -qF "${aws_cloud9_key_name_15}" ${user_authorized_keys_file} || echo "${aws_cloud9_public_key_15}}" >> ${user_authorized_keys_file}
grep -qF "${aws_cloud9_key_name_16}" ${user_authorized_keys_file} || echo "${aws_cloud9_public_key_16}}" >> ${user_authorized_keys_file}

chmod 600 ${user_authorized_keys_file}

# delete public key inserted by packer during the ami build.
sed -i -e "/packer/d" ${user_authorized_keys_file}

# configure fso lab environment variables for user. ------------------------------------------------
# set current date for temporary filename.
curdate=$(date +"%Y-%m-%d.%H-%M-%S")

# set fso lab environment configuration variables.
user_bash_config_file="${user_home}/.bashrc"
fso_lab_number="$(printf '%02d' ${lab_number})"

# save a copy of the current file.
if [ -f "${user_bash_config_file}.orig" ]; then
  cp -p ${user_bash_config_file} ${user_bash_config_file}.${curdate}
else
  cp -p ${user_bash_config_file} ${user_bash_config_file}.orig
fi

# use the stream editor to substitute the new values.
sed -i -e "/^aws_region_name/s/^.*$/aws_region_name=\"${aws_region_name}\"/" ${user_bash_config_file}
sed -i -e "/^aws_eks_cluster_name/s/^.*$/aws_eks_cluster_name=\"${aws_eks_cluster_name}\"/" ${user_bash_config_file}
sed -i -e "/^eks_kubeconfig_filepath/s/^.*$/eks_kubeconfig_filepath=\"\$HOME\/.kube\/config\"/" ${user_bash_config_file}
sed -i -e "/^iks_cluster_name/s/^.*$/iks_cluster_name=\"${iks_cluster_name}\"/" ${user_bash_config_file}
sed -i -e "/^iks_kubeconfig_filepath/s/^.*$/iks_kubeconfig_filepath=\"\$HOME\/${iks_kubeconfig_file}\"/" ${user_bash_config_file}
sed -i -e "/^fso_lab_number/s/^.*$/fso_lab_number=\"${fso_lab_number}\"/" ${user_bash_config_file}

# configure the hostname of the aws ec2 instance. --------------------------------------------------
# export environment variables.
export aws_ec2_hostname
export aws_ec2_domain

# set the hostname.
./config_al2_system_hostname.sh
