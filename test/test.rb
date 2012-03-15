require './lib/zinx'

search 'nike' do
	puts matches.first.nome
end

# # # class Test
# # # 	extend Zinx::Search

# # # 	search 'nike' do 
# # # 		ap matches
# # # 	end
# # # end