", "# terraform-aws-r53-resolver-rules
Route53 Resolver Rules Module - simplifies what to code up for each new rule even if we only have 1-2 endpoints

## Introduction

This module makes creating rules and all the usual RAM associations accross all accounts far easier to code. The calling code does not need to have all the various resources coded out, just the rules list with the added variables.

This module will create:

forwarding rules
rule associations to existing endpoint
ram shares
ram associations


## Parameters

### rule_name

Name the rule after the type and domain name

|Initial Rules as Examples  |
|---------------------|
| r53fwd-ad.ucop.edu     |
| r53fwd-adlab.ucop.edu  |

### domain_name

The domain to forward lookups for; this is matched in all lookups to r53 .2 resolved in the VPC and if matched is sent to the outbound endpoint that will send the look to UCOP NS hosts defined there.

Must be the actual domain, and names under must be in or resolvable by UCOP NS hosts

|Initial Examples  |
|------------------|
| ad.ucop.edu      |
| adlab.ucop.edu   |

### ram_name

Is the name for the share that will be seen in the console and these should be named after the rule you created

|Initial Rules as Examples   |
|----------------------------|
| ram-r53fwd-ad.ucop.edu     |
| ram-r53fwd-adlab.ucop.edu  |

### vpc_id

The VPC ID is always the Resolver's VPC, currently vpc-01b2959303cc120c8. Note this is in net-prod and not seg-dns as seg-dns has no VPC, etc. and we decided to keep it minimal and not add one for this. Also networking team has all other "running" or "aws services" in net-prod and works there more than seg-dns which has only our r53 zone delegations/stub zones.

| VPC ID                |
|-----------------------|
| vpc-01b2959303cc120c8 |

### ips

A list. The ns hosts to forward to. We use four for added HA. Do not use the name, it is below only for convenience and to easily spot future updates should we replace any of these

| IPs | Name |
| 10.49.62.153 | ns16aws.ucop.edu (UCOP AWS) |
| 128.48.216.10 | ns4.ucop.edu (Oakland) |
| 128.48.89.70 | ns5.ucop.edu (SDSC) |
| 128.48.89.71 | ns6.ucop.edu (SDSC) |

Such as ips = ["10.49.62.153", "128.48.216.10", "128.48.89.70", "128.48.89.71"]


### principals

The account ids to share the rules to. This is a list.

| Account ID |
| 111111111111 |

Such as principals  = ["111111111111", "111111111112", "111111111113", "111111111114"]


## Usage


```
# Must have an existing endpoint or create one
#  UCOP has plans in 2024 for just the one outbound and only to use netprod. The real reason
#  for this module is the simplification of the rules and ram work if each were to be there
#  own resource blocks

module "sg1" {
  source = "git::https://git@github.com/ucopacme/terraform-aws-security-group.git//"
  name   = join("-", [local.application, local.environment, local.host_type, "ec2", "sg"])
  vpc_id = local.vpc_id
  ingress = [
    {
      from_port   = 53
      to_port     = 53
      protocol    = "ucp"
      cidr_blocks = ["128.48.64.0/19"]
      description = "Allow SSH from UCOP Network"
    },
    {
      from_port   = 53
      to_port     = 53
      protocol    = "tcp"
      self        = true
      description = "Allow SSH/SCP between app servers"
    },
  ]
  egress = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "all"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow egress to anywhere"
    },
  ]

  tags = merge(tomap({ "Name" = join("-", [local.application, local.environment, local.host_type, "ec2", "sg"]) }), local.tags)
}


resource "aws_route53_resolver_endpoint" "outbound" {
  name      = "r53-outbound-endpoint"
  direction = "OUTBOUND"

  security_group_ids = [
    module.sg1.id
  ]

  ip_address {
    subnet_id = local.subnet_id1
    ip        = "10.49.62.140" #hard coded for delete/recreate to stay say--if vpc changes, change this
  }

  ip_address {
    subnet_id = local.subnet_id2
    ip        = "10.49.62.180" #hard coded for delete/recreate to stay say--if vpc changes, change this
  }

  protocols = ["Do53", "DoH"]

  tags = {
    Environment = "Prod"
  }
}


module "r53-resolver-rules" {
  source               = "git::https://github.com/ucopacme/terraform-aws-r53-resolver-rules.git"
  resolver_endpoint_id = aws_route53_resolver_endpoint.outbound.id

  rules = [
    { rule_name   = "r53fwd-testzone1.ucop.edu"
      domain_name = "testzone.ucop.edu."
      ram_name    = "ram-r53fwd-testzone1.ucop.edu"
      vpc_ids     = ["vpc-01b2959303cc120c8"]
      ips         = ["10.49.62.153", "128.48.216.10", "128.48.89.70", "128.48.89.71"]
      principals  = ["111111111111", "111111111112", "111111111113", "111111111114"]
    },
    { rule_name   = "r53fwd-testzone2.ucop.edu"
      domain_name = "testzone.ucop.edu."
      ram_name    = "ram-r53fwd-testzone1.ucop.edu"
      vpc_ids     = ["vpc-01b2959303cc120c8"]
      ips         = ["10.49.62.153", "128.48.216.10", "128.48.89.70", "128.48.89.71"]
      principals  = ["111111111111", "111111111112", "111111111113", "111111111114"]
    },
    { rule_name   = "r53fwd-testzone3.ucop.edu"
      domain_name = "testzone.ucop.edu."
      ram_name    = "ram-r53fwd-testzone1.ucop.edu"
      vpc_ids     = ["vpc-01b2959303cc120c8"]
      ips         = ["10.49.62.153", "128.48.216.10", "128.48.89.70", "128.48.89.71"]
      principals  = ["111111111111", "111111111112", "111111111113", "111111111114"]
    }
  ]
}
```

### Notes

As of 4/2024 this is a current list of all principals, though it includes some without VPCs or that are unmanaged... a share can still be created though
principals = ["013263325064", "018938320552", "022327690785", "030333339593", "032821990254", "041008331506", "052061647996", "055100249131", "066535528908", "074589347111", "093394219900", "114384331015", "126174681068", "157304172948", "169454577458", "202481898613", "205487787993", "211125413418", "211125414478", "211125590966", "221631899669", "229341609947", "261032852138", "276210538364", "280181752709", "327017052424", "353876084054", "381492104485", "404845395086", "443591488593", "465872772557", "469462193597", "471112755263", "497286016891", "503759735250", "519550777117", "580460105188", "610765387508", "613074250484", "613726763327", "627602613099", "637423188783", "674555972331", "702425941516", "730335191998", "737379256701", "836626524524", "863929767085", "872008829419", "873964403035", "897194160541", "905418046461", "905418358248", "910626626856", "921671357694", "944706592399", "953452961393", "963832791377", "975018909096", "991195326434", "994872636351", "999307947890", "999860890886"]

Testing should be done carefully and not with ad or adlab


Accounts currently with VPCs (though rules can be shared with all)
- 910626626856    I2E2-prod
- 327017052424    OrgMaster
- 221631899669    UCOP SharePoint
- 637423188783    anr-dev
- 211125590966    anr-prod
- 013263325064    applyuc-dev
- 404845395086    applyuc-prod
- 465872772557    big-dev
- 066535528908    big-prod
- 580460105188    ccure-prod
- 944706592399    chs-dev
- 674555972331    dba-dev
- 055100249131    dr-prod
- 613074250484    fdw-dev
- 280181752709    fdw-prod
- 872008829419    finapps-dev
- 836626524524    finapps-prod
- 999860890886    fis-dev
- 702425941516    fis-prod
- 730335191998    fow-dev
- 905418046461    fow-prod
- 211125413418    iam-dev
- 381492104485    iam-prod
- 863929767085    invt-dev
- 999307947890    invt-prod
- 169454577458    irap-prod
- 022327690785    iso-dev
- 921671357694    iso-prod
- 074589347111    ldc
- 052061647996    net-dev
- 443591488593    net-prod
- 030333339593    ppersdev
- 503759735250    ppersprod
- 202481898613    redline-dev
- 032821990254    ru-prod
- 519550777117    rwd-dev
- 953452961393    rwd-prod
- 276210538364    rwd-sharedsvcs
- 041008331506    segLog
- 471112755263    shs-prod
- 897194160541    tes-prod
- 873964403035    uclegal-prod
- 469462193597    ucop-setdev
- 905418358248    ucop-sharedsvcs
- 018938320552    wae-dev
- 497286016891    was-build
- 975018909096    wla-dev
- 205487787993    wla-prod

Could share or not with these that do not have VPCs
- 627602613099    mf-dev
- 610765387508    mf-locProd
- 261032852138    mf-prod
- 613726763327    seg-dns
- 737379256701    segConf
- 114384331015    stm-dev
- 991195326434    uchealth-swcur-prod
-
