require 'test_helper'

class Admin::CompetitorsControllerTest < ActionController::TestCase
  setup do
    @competitor = competitors(:flo_aachen_open)
    @competition = @competitor.competition
    login_as(@competition.users.first)

    @new_competitor_params = {
      wca: '2000BOB01',
      first_name: 'bob',
      last_name: 'bobsen',
      email: 'bob@cubecomp.de',

      :"birthday(1i)" => '1980',
      :"birthday(2i)" => '02',
      :"birthday(3i)" => '01',

      country_id: countries(:germany).id,
      local: true,
      gender: 'male',
      nametag: 'bob!',

      staff: true,
      confirmation_email_sent: false,

      free_entrance: true,
      free_entrance_reason: 'free moneys!',
      paid: true,
      paid_comment: 'moneys!',

      user_comment: 'hello',
      admin_comment: 'this guy is awesome',

      days: {
        @competition.events.first.day_id.to_s => {
          status: 'competitor',
          events: {
            @competition.events.first.id.to_s => {
              status: 'registered'
            }
          }
        }
      }
    }

    @update_params = {
      admin_comment: 'this guy is awesome',
      country_id: countries(:germany).id,
      email: 'bob@cubecomp.de',
      first_name: 'bob',
      last_name: 'bobsen',
      free_entrance: true,
      free_entrance_reason: 'free moneys!',
      local: true,
      paid: true,
      paid_comment: 'moneys!',
      staff: true,
      user_comment: 'hello',
      wca: '2000BOB01',
      state: 'confirmed',
      :"birthday(1i)" => '1980',
      :"birthday(2i)" => '02',
      :"birthday(3i)" => '01'
    }
  end

  test '#index' do
    get :index, params: { competition_id: @competition.id }
    assert_response :success
  end

  test '#checklist' do
    get :checklist, params: { competition_id: @competition.id }
    assert_response :success
  end

  test '#csv' do
    @competition.competitors.each{ |competitor| competitor.update_attributes(state: 'confirmed') }
    get :csv, params: { competition_id: @competition.id }
    assert_response :success
  end

  test '#csv_download_active' do
    @competition.competitors.each{ |competitor| competitor.update_attributes(state: 'confirmed') }
    get :csv_download_active, params: { competition_id: @competition.id }
    assert_response :success

    expected = []
    expected << "Status,Name,Country,WCA ID,Birth Date,Gender,,333,444,555"
    expected << "a,Florian Weingarten,Germany,2007WEIN01,1985-12-18,m,,1,0,1"

    assert_equal expected.join("\n"), response.body
    assert_equal "text/csv", response.content_type
    assert_equal 'attachment; filename="Aachen Open 2014.csv"', response.headers['Content-Disposition']
  end

  test '#nametags' do
    get :nametags, params: { competition_id: @competition.id }
    assert_response :success
  end

  test '#email_addresses' do
    get :email_addresses, params: { competition_id: @competition.id }
    assert_response :success
  end

  test '#index renders 404 with invalid competition id' do
    get :index, params: { competition_id: 17 }
    assert_response :not_found
  end

  test '#index without login permission renders 401' do
    mock_login_not_allowed(@competition)
    get :index, params: { competition_id: @competition.id }
    assert_response :forbidden
  end

  test '#new' do
    get :new, params: { competition_id: @competition.id }
    assert_response :success
  end

  test '#new without login permission renders 401' do
    mock_login_not_allowed(@competition)
    get :new, params: { competition_id: @competition.id }
    assert_response :forbidden
  end

  test '#create' do
    assert_difference '@competition.competitors.count', +1 do
      assert_difference '@competition.event_registrations.count', +1 do
        assert_difference '@competition.day_registrations.count', +1 do
          post :create, params: {
            competition_id: @competition.id,
            competitor: @new_competitor_params
          }
        end
      end
    end

    assert_response :redirect
    assert_redirected_to admin_competition_competitors_path(@competition.id)
    bob = @competition.competitors.find_by(wca: '2000BOB01')
    expected = @new_competitor_params.except(:"birthday(1i)", :"birthday(2i)", :"birthday(3i)", :days)
    assert_attributes(expected, bob)
    assert_equal @new_competitor_params[:"birthday(1i)"].to_i, bob.birthday.year
    assert_equal @new_competitor_params[:"birthday(2i)"].to_i, bob.birthday.month
    assert_equal @new_competitor_params[:"birthday(3i)"].to_i, bob.birthday.day
  end

  test '#create without login permission renders 401' do
    mock_login_not_allowed(@competition)

    assert_no_difference 'Competitor.count' do
      post :create, params: {
        competition_id: @competition.id,
        competitor: @new_competitor_params
      }
    end

    assert_response :forbidden
  end

  test '#edit' do
    get :edit, params: {
      competition_id: @competition.id,
      id: @competitor.id
    }

    assert_response :success
  end

  test '#edit without login permission renders 401' do
    mock_login_not_allowed(@competition)

    get :edit, params: {
      competition_id: @competition.id,
      id: @competitor.id
    }

    assert_response :forbidden
  end

  test '#update' do
    patch :update, params: {
      competition_id: @competition.id,
      id: @competitor.id,
      competitor: @update_params
    }

    assert_redirected_to admin_competition_competitors_path(@competition.id)
    @competitor.reload
    assert_attributes(@update_params.except(:"birthday(1i)", :"birthday(2i)", :"birthday(3i)"), @competitor)
    assert_equal @update_params[:"birthday(1i)"].to_i, @competitor.birthday.year
    assert_equal @update_params[:"birthday(2i)"].to_i, @competitor.birthday.month
    assert_equal @update_params[:"birthday(3i)"].to_i, @competitor.birthday.day
  end

  test '#confirm' do
    @competitor.update_attributes(state: 'new')

    patch :confirm, params: {
      competition_id: @competition.id,
      id: @competitor.id
    }

    assert_equal 'confirmed', @competitor.reload.state
  end

  test '#cancel' do
    @competitor.update_attributes(state: 'new')

    patch :cancel, params: {
      competition_id: @competition.id,
      id: @competitor.id
    }

    assert_equal 'cancelled', @competitor.reload.state
  end

  test '#mark_as_paid' do
    @competitor.update_attributes(paid: false)

    patch :mark_as_paid, params: {
      competition_id: @competition.id,
      id: @competitor.id
    }

    assert_equal true, @competitor.reload.paid
  end

  test '#update without login permission renders 401' do
    mock_login_not_allowed(@competition)

    patch :update, params: {
      competition_id: @competition.id,
      id: @competitor.id,
      competitor: @update_params
    }

    assert_response :forbidden
  end

  test '#update to change day registration from not_registered to guest' do
    competitor = competitors(:aachen_open_day_one_guest)
    event = events(:aachen_open_rubiks_revenge_day_two)

    assert_difference 'competitor.day_registrations.count', +1 do
      assert_no_difference 'EventRegistration.count' do
        patch :update, params: {
          competition_id: @competition.id,
          id: competitor.id,
          competitor: {
            days: {
              event.day_id.to_s => {
                status: 'guest',
                events: {
                  event.id.to_s => {
                    status: 'not_registered'
                  }
                }
              }
            }
          }
        }
      end
    end

    assert competitor.reload.guest_on?(event.day)
  end

  test '#update to change day registration from not_registered to registered' do
    competitor = competitors(:aachen_open_day_one_guest)
    event = events(:aachen_open_rubiks_revenge_day_two)

    assert_difference 'competitor.day_registrations.count', +1 do
      assert_difference 'competitor.event_registrations.count', +1 do
        patch :update, params: {
          competition_id: @competition.id,
          id: competitor.id,
          competitor: {
            days: {
              event.day_id.to_s => {
                status: 'registered',
                events: {
                  event.id.to_s => {
                    status: 'registered'
                  }
                }
              }
            }
          }
        }
      end
    end

    assert competitor.reload.competing_on?(event.day)
    assert competitor.reload.events.include?(event)
  end

  test '#update to change day registration from guest to not_registered' do
    competitor = competitors(:aachen_open_both_days_guest)
    day = days(:aachen_open_day_one)
    event = day.events.first

    assert_difference 'competitor.day_registrations.count', -1 do
      assert_no_difference 'competitor.event_registrations.count' do
        patch :update, params: {
          competition_id: @competition.id,
          id: competitor.id,
          competitor: {
            days: {
              day.id.to_s => {
                status: 'not_registered',
                events: {
                  event.id.to_s => {
                    status: 'not_registered'
                  }
                }
              }
            }
          }
        }
      end
    end

    refute competitor.registered_on?(event.day)
  end

  test '#update to change day registration from guest to competitor' do
    competitor = competitors(:aachen_open_day_one_guest)
    day = days(:aachen_open_day_one)
    event = day.events.first

    assert_no_difference 'competitor.day_registrations.count' do
      assert_difference 'competitor.event_registrations.count', +1 do
        patch :update, params: {
          competition_id: @competition.id,
          id: competitor.id,
          competitor: {
            days: {
              day.id.to_s => {
                status: 'registered',
                events: {
                  event.id.to_s => {
                    status: 'registered'
                  }
                }
              }
            }
          }
        }
      end
    end

    assert competitor.reload.competing_on?(event.day)
    assert competitor.reload.events.include?(event)
  end

  test '#update to change day registration from competitor to not_registered' do
    event = @competitor.events.first
    day = event.day

    other_day = @competition.days.detect{ |d| d != day }
    RegistrationService.new(@competitor).register_as_guest(other_day.id)
    @competitor.save!

    events = {}
    @competitor.events.where(day: day).each do |e|
      # because checkboxes will still be checked in the form
      events[e.id.to_s] = { status: 'registered' }
    end

    assert_difference '@competitor.day_registrations.count', -1 do
      assert_difference '@competitor.event_registrations.count', -1 * events.keys.size do
        patch :update, params: {
          competition_id: @competition.id,
          id: @competitor.id,
          competitor: {
            days: {
              day.id.to_s => {
                status: 'not_registered',
                events: events
              }
            }
          }
        }
      end
    end

    refute @competitor.reload.registered_on?(event.day)
    refute @competitor.reload.events.include?(event)
  end

  test '#update to change day registration from competitor to guest' do
    event = @competitor.events.first
    day = event.day

    events = {}
    @competitor.events.where(day: day).each do |e|
      # because checkboxes will still be checked in the form
      events[e.id.to_s] = { status: 'registered' }
    end

    assert_no_difference '@competitor.day_registrations.count' do
      assert_difference '@competitor.event_registrations.count', -1 * events.keys.size do
        patch :update, params: {
          competition_id: @competition.id,
          id: @competitor.id,
          competitor: {
            days: {
              day.id.to_s => {
                status: 'guest',
                events: events
              }
            }
          }
        }
      end
    end

    assert @competitor.reload.guest_on?(event.day)
  end

  test '#update to change event registration from not_registered to waiting' do
    competitor = competitors(:aachen_open_day_one_guest)
    day = days(:aachen_open_day_one)
    event = day.events.first

    assert_no_difference 'competitor.day_registrations.count' do
      assert_difference 'competitor.event_registrations.count', +1 do
        patch :update, params: {
          competition_id: @competition.id,
          id: competitor.id,
          competitor: {
            days: {
              day.id.to_s => {
                status: 'registered',
                events: {
                  event.id.to_s => {
                    status: 'waiting'
                  }
                }
              }
            }
          }
        }
      end
    end

    assert competitor.reload.event_registrations.where(event: event).first.waiting
  end

  test '#update to change all event registrations to not_registered changes day registration to guest' do
    event = @competitor.events.first
    day = event.day

    events = {}
    @competitor.events.where(day: day).each do |e|
      # because checkboxes will still be checked in the form
      events[e.id.to_s] = { status: 'not_registered' }
    end

    assert_no_difference '@competitor.day_registrations.count' do
      assert_difference '@competitor.event_registrations.count', -1 * events.keys.size do
        patch :update, params: {
          competition_id: @competition.id,
          id: @competitor.id,
          competitor: {
            days: {
              day.id.to_s => {
                status: 'registered',
                events: events
              }
            }
          }
        }
      end
    end

    assert @competitor.reload.guest_on?(event.day)
  end

  test '#destroy' do
    assert_difference '@competition.competitors.count', -1 do
      delete :destroy, params: {
        competition_id: @competition.id,
        id: @competitor.id
      }
    end

    assert_redirected_to admin_competition_competitors_path(@competition.id)
  end

  test '#destroy without login permission renders 401' do
    mock_login_not_allowed(@competition)

    assert_no_difference 'Competitor.count' do
      delete :destroy, params: {
        competition_id: @competition.id,
        id: @competitor.id
      }
    end

    assert_response :forbidden
  end
end
