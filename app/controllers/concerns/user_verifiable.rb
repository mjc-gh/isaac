# frozen_string_literal: true

module UserVerifiable
  extend ActiveSupport::Concern

  def verify
    @user = User.find_by_magic_link_token(params[:token], for: verification_purpose)

    if @user.nil?
      redirect_on_verification_failed
    else
      handle_verification_success
    end
  end

  private

  def verification_purpose = controller_name.singularize.to_sym
end
