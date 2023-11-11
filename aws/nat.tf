



# resource "aws_route_table" "nat_route" {
#   vpc_id = aws_vpc.rpl-vpc.id
#   route {
#     cidr_block = "0.0.0.0/0"
#     nat_gateway_id = aws_nat_gateway.nat_gateway.id
#   }
# }

# resource "aws_route_table_association" "private_route_a" {
#   subnet_id = aws_subnet.subnet-1.id
#   route_table_id = aws_route_table.nat_route.id
# }

# resource "aws_route_table_association" "private_route_b" {
#   subnet_id = aws_subnet.subnet-2.id
#   route_table_id = aws_route_table.nat_route.id
# }

# # resource "aws_route_table_association" "private_route_c" {
# #   subnet_id = aws_subnet.subnet-3.id
# #   route_table_id = aws_route_table.nat_route.id
# # }